import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ANALYTICS PAGE — Feature Added: Trend charts, resolution metrics,
// category breakdown, priority distribution, engineer workload.
// Previously missing from the project; all data is sourced from Firestore
// in real time using StreamBuilder.
// ═══════════════════════════════════════════════════════════════════════════
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // SLA target hours per priority level — used for compliance rate computation
  static const Map<String, int> _slaHours = {
    'Critical': 4,
    'High': 8,
    'Medium': 24,
    'Low': 72,
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            '/engineer-dashboard',
          ),
        ),
        actions: [
          // Profile button in top-right consistent with engineer dashboard
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<dynamic>(
              icon: const Icon(Icons.account_circle_rounded),
              itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    user?.displayName ?? 'Engineer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: const Row(children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ]),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Single snapshot of all tickets — drives every chart on this page
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading analytics: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            );
          }

          // Extract all ticket documents
          final docs = snapshot.data?.docs ?? [];

          // ── Compute all metrics ──────────────────────────────────────────

          // Status distribution counts
          int openCount = 0;
          int inProgressCount = 0;
          int resolvedCount = 0;

          // Category breakdown map
          final Map<String, int> categoryMap = {};

          // Priority breakdown map
          final Map<String, int> priorityMap = {
            'Critical': 0,
            'High': 0,
            'Medium': 0,
            'Low': 0,
          };

          // Monthly ticket volume — last 6 months
          final Map<String, int> monthlyMap = {};
          final now = DateTime.now();
          for (int i = 5; i >= 0; i--) {
            final month = DateTime(now.year, now.month - i, 1);
            final key = DateFormat('MMM yy').format(month);
            monthlyMap[key] = 0;
          }

          // Resolution time accumulator by priority (for average computation)
          final Map<String, List<double>> resolutionTimes = {
            'Critical': [],
            'High': [],
            'Medium': [],
            'Low': [],
          };

          // Engineer workload (tickets assigned per engineer name)
          final Map<String, int> engineerWorkload = {};

          // SLA compliance counters per priority
          final Map<String, int> slaCompliant = {
            'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0
          };
          final Map<String, int> slaTotal = {
            'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0
          };

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Status counts
            final status = data['status'] as String? ?? 'Open';
            if (status == 'Open') {
              openCount++;
            } else if (status == 'In Progress') {
              inProgressCount++;
            } else if (status == 'Resolved') {
              resolvedCount++;
            }

            // Category breakdown
            final category = data['category'] as String? ?? 'Other';
            categoryMap[category] = (categoryMap[category] ?? 0) + 1;

            // Priority breakdown
            final priority = data['priority'] as String? ?? 'Medium';
            if (priorityMap.containsKey(priority)) {
              priorityMap[priority] = priorityMap[priority]! + 1;
            }

            // Monthly volume — bucket ticket into its creation month
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final dt = createdAt.toDate();
              final key = DateFormat('MMM yy').format(dt);
              if (monthlyMap.containsKey(key)) {
                monthlyMap[key] = monthlyMap[key]! + 1;
              }
            }

            // Average resolution time — only for resolved tickets
            if (status == 'Resolved' && createdAt != null) {
              final updatedAt = data['updatedAt'] as Timestamp?;
              if (updatedAt != null) {
                // Resolution time in hours
                final hours = updatedAt
                    .toDate()
                    .difference(createdAt.toDate())
                    .inMinutes / 60.0;
                if (resolutionTimes.containsKey(priority)) {
                  resolutionTimes[priority]!.add(hours);
                }

                // SLA compliance — was ticket resolved within SLA target?
                final slaTarget = _slaHours[priority] ?? 24;
                if (slaTotal.containsKey(priority)) {
                  slaTotal[priority] = slaTotal[priority]! + 1;
                  if (hours <= slaTarget) {
                    slaCompliant[priority] = slaCompliant[priority]! + 1;
                  }
                }
              }
            }

            // Engineer workload — count tickets assigned to each engineer
            final assignedTo = data['assignedToName'] as String?;
            if (assignedTo != null && assignedTo.isNotEmpty) {
              engineerWorkload[assignedTo] =
                  (engineerWorkload[assignedTo] ?? 0) + 1;
            }
          }

          // Compute average resolution hours per priority
          final Map<String, double> avgResolution = {};
          resolutionTimes.forEach((priority, times) {
            if (times.isNotEmpty) {
              avgResolution[priority] =
                  times.reduce((a, b) => a + b) / times.length;
            } else {
              avgResolution[priority] = 0;
            }
          });

          // ── Build the page ───────────────────────────────────────────────
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page title
                    const Text(
                      'Analytics Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Live metrics across all tickets in the system',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Row 1: Summary stat cards ──────────────────────────
                    _buildSummaryRow(
                      docs.length,
                      openCount,
                      inProgressCount,
                      resolvedCount,
                      isMobile,
                    ),
                    const SizedBox(height: 24),

                    // ── Row 2: Status distribution + Category breakdown ────
                    isMobile
                        ? Column(children: [
                            _buildStatusDistributionChart(
                                openCount, inProgressCount, resolvedCount),
                            const SizedBox(height: 20),
                            _buildCategoryChart(categoryMap),
                          ])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildStatusDistributionChart(
                                    openCount, inProgressCount, resolvedCount),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildCategoryChart(categoryMap),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // ── Row 3: Monthly trend chart ─────────────────────────
                    _buildMonthlyTrendChart(monthlyMap),
                    const SizedBox(height: 24),

                    // ── Row 4: Priority breakdown + Avg resolution time ────
                    isMobile
                        ? Column(children: [
                            _buildPriorityChart(priorityMap),
                            const SizedBox(height: 20),
                            _buildResolutionTimeChart(avgResolution),
                          ])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildPriorityChart(priorityMap)),
                              const SizedBox(width: 20),
                              Expanded(
                                  child:
                                      _buildResolutionTimeChart(avgResolution)),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // ── Row 5: SLA compliance rate ─────────────────────────
                    _buildSlaComplianceChart(slaCompliant, slaTotal),
                    const SizedBox(height: 24),

                    // ── Row 6: Engineer workload ───────────────────────────
                    _buildEngineerWorkloadChart(engineerWorkload),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Summary stat cards (total, open, in-progress, resolved) ──────────────
  Widget _buildSummaryRow(
    int total,
    int open,
    int inProgress,
    int resolved,
    bool isMobile,
  ) {
    final cards = [
      _buildSmallStatCard('Total', total.toString(),
          Icons.confirmation_number_rounded, const Color(0xFF8B5CF6)),
      _buildSmallStatCard('Open', open.toString(),
          Icons.inbox_rounded, const Color(0xFF3B82F6)),
      _buildSmallStatCard('In Progress', inProgress.toString(),
          Icons.timelapse_rounded, const Color(0xFFF59E0B)),
      _buildSmallStatCard('Resolved', resolved.toString(),
          Icons.check_circle_rounded, const Color(0xFF10B981)),
    ];

    if (isMobile) {
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ]);
    }

    return Row(children: [
      for (int i = 0; i < cards.length; i++) ...[
        Expanded(child: cards[i]),
        if (i < cards.length - 1) const SizedBox(width: 16),
      ],
    ]);
  }

  Widget _buildSmallStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Shared card wrapper used by all charts ─────────────────────────────
  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              )),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ── Status distribution — horizontal bar chart ─────────────────────────
  Widget _buildStatusDistributionChart(int open, int inProgress, int resolved) {
    final total = open + inProgress + resolved;
    return _buildChartCard(
      title: 'Ticket Status Distribution',
      child: Column(children: [
        _buildHorizontalBar('Open', open, total, const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildHorizontalBar(
            'In Progress', inProgress, total, const Color(0xFFF59E0B)),
        const SizedBox(height: 12),
        _buildHorizontalBar('Resolved', resolved, total, const Color(0xFF10B981)),
      ]),
    );
  }

  // ── Category breakdown — horizontal bars ──────────────────────────────
  Widget _buildCategoryChart(Map<String, int> categoryMap) {
    final total =
        categoryMap.values.fold(0, (acc, v) => acc + v);
    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildChartCard(
      title: 'Tickets by Category',
      child: Column(
        children: sorted
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHorizontalBar(
                      e.key, e.value, total, const Color(0xFF0066FF)),
                ))
            .toList(),
      ),
    );
  }

  // ── Reusable horizontal bar row with label + value + percentage ──────────
  Widget _buildHorizontalBar(
      String label, int value, int total, Color color) {
    // Compute fill fraction (guard against divide-by-zero)
    final fraction = total > 0 ? value / total : 0.0;
    final pct = (fraction * 100).toStringAsFixed(1);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500)),
          ),
          Text('$value ($pct%)',
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 6),
      // Track (grey background)
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 10, color: const Color(0xFFF3F4F6)),
          // Fill (proportional width)
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Monthly ticket volume — vertical bar chart (last 6 months) ───────────
  Widget _buildMonthlyTrendChart(Map<String, int> monthlyMap) {
    final maxVal =
        monthlyMap.values.fold(0, (m, v) => v > m ? v : m);

    return _buildChartCard(
      title: 'Ticket Volume — Last 6 Months',
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthlyMap.entries.map((entry) {
            // Height fraction for this month's bar
            final heightFraction =
                maxVal > 0 ? entry.value / maxVal : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count label above bar
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0066FF)),
                    ),
                    const SizedBox(height: 4),
                    // The bar itself
                    Container(
                      height: 120 * heightFraction.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Month label below bar
                    Text(
                      entry.key,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Priority distribution — color-coded bars ───────────────────────────
  Widget _buildPriorityChart(Map<String, int> priorityMap) {
    final total =
        priorityMap.values.fold(0, (acc, v) => acc + v);
    final colors = {
      'Critical': const Color(0xFFEF4444),
      'High': const Color(0xFFF97316),
      'Medium': const Color(0xFF3B82F6),
      'Low': const Color(0xFF10B981),
    };

    return _buildChartCard(
      title: 'Tickets by Priority',
      child: Column(
        children: priorityMap.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHorizontalBar(
                e.key, e.value, total, colors[e.key] ?? const Color(0xFF6B7280)),
          );
        }).toList(),
      ),
    );
  }

  // ── Average resolution time by priority ──────────────────────────────
  Widget _buildResolutionTimeChart(Map<String, double> avgResolution) {
    // Find the max avg hours to normalise bar widths
    final maxHours =
        avgResolution.values.fold(0.0, (m, v) => v > m ? v : m);
    final colors = {
      'Critical': const Color(0xFFEF4444),
      'High': const Color(0xFFF97316),
      'Medium': const Color(0xFF3B82F6),
      'Low': const Color(0xFF10B981),
    };

    return _buildChartCard(
      title: 'Avg Resolution Time (hrs)',
      child: Column(
        children: avgResolution.entries.map((e) {
          final fraction = maxHours > 0 ? e.value / maxHours : 0.0;
          final color =
              colors[e.key] ?? const Color(0xFF6B7280);
          final slaTarget = _slaHours[e.key] ?? 24;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A))),
                    // Show hours vs SLA target
                    Text(
                      e.value > 0
                          ? '${e.value.toStringAsFixed(1)}h  (SLA: ${slaTarget}h)'
                          : 'No data',
                      style: TextStyle(
                          fontSize: 12,
                          color: (e.value > slaTarget && e.value > 0)
                              ? const Color(0xFFEF4444)
                              : color,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 10, color: const Color(0xFFF3F4F6)),
                    FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          // Red bar if over SLA, normal colour otherwise
                          color: (e.value > slaTarget && e.value > 0)
                              ? const Color(0xFFEF4444)
                              : color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SLA compliance rate per priority ──────────────────────────────────
  Widget _buildSlaComplianceChart(
      Map<String, int> compliant, Map<String, int> total) {
    final colors = {
      'Critical': const Color(0xFFEF4444),
      'High': const Color(0xFFF97316),
      'Medium': const Color(0xFF3B82F6),
      'Low': const Color(0xFF10B981),
    };

    return _buildChartCard(
      title: 'SLA Compliance Rate (Resolved Tickets)',
      child: Column(
        children: ['Critical', 'High', 'Medium', 'Low'].map((priority) {
          final t = total[priority] ?? 0;
          final c = compliant[priority] ?? 0;
          final pct = t > 0 ? (c / t * 100) : 0.0;
          final color = colors[priority]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(priority,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A))),
                    Text(
                      t > 0
                          ? '${pct.toStringAsFixed(0)}%  ($c / $t)'
                          : 'No data',
                      style: TextStyle(
                          fontSize: 12,
                          // Green if >= 80%, red if < 80%
                          color: pct >= 80
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 10, color: const Color(0xFFF3F4F6)),
                    FractionallySizedBox(
                      widthFactor: (pct / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: pct >= 80
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Engineer workload — tickets assigned per engineer ──────────────────
  Widget _buildEngineerWorkloadChart(Map<String, int> workload) {
    if (workload.isEmpty) {
      return _buildChartCard(
        title: 'Engineer Workload',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tickets have been assigned to engineers yet.',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final total = workload.values.fold(0, (acc, v) => acc + v);
    final sorted = workload.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildChartCard(
      title: 'Engineer Workload (Assigned Tickets)',
      child: Column(
        children: sorted
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHorizontalBar(
                    e.key,
                    e.value,
                    total,
                    const Color(0xFF8B5CF6),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
