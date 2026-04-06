import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// package:web is the modern Flutter-Web interop library (replaces dart:html)
// used exclusively for the CSV download anchor-click trick.
import 'package:web/web.dart' as web;

// ═══════════════════════════════════════════════════════════════════════════
// ENGINEER DASHBOARD — Features Added:
//   • SLA Warning Badges   — ticket cards gain a red/amber badge when a
//     ticket has breached or is approaching its priority SLA target.
//   • CSV Export           — "Export CSV" button downloads the currently
//     filtered ticket list as a UTF-8 CSV file (Flutter Web only via dart:html).
//   • Notifications Bell   — real-time unread count from Firestore;
//     tapping opens a dropdown showing recent notifications with mark-as-read.
//   • Analytics Navigation — AppBar button routes to /analytics.
//   • Settings Navigation  — previously empty onTap now routes to /settings.
//   • Profile Navigation   — routes to /profile.
// ═══════════════════════════════════════════════════════════════════════════
class EngineerDashboard extends StatefulWidget {
  const EngineerDashboard({super.key});

  @override
  State<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends State<EngineerDashboard> {
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _statuses = ['All', 'Open', 'In Progress', 'Resolved'];
  final List<String> _priorities = [
    'All', 'Critical', 'High', 'Medium', 'Low'
  ];
  final List<String> _categories = [
    'All',
    'Network Issues',
    'Software Problems',
    'Hardware Issues',
    'Account & Access',
    'Other',
  ];

  // SLA target hours per priority — drives the warning badges on cards
  static const Map<String, int> _slaHours = {
    'Critical': 4,
    'High': 8,
    'Medium': 24,
    'Low': 72,
  };

  // The last filtered list is stored so the CSV export can use it
  List<QueryDocumentSnapshot> _lastFilteredTickets = [];

  // ── SLA Helper ───────────────────────────────────────────────────────────

  // Returns null if within SLA, or a coloured label string + colour if over
  Map<String, dynamic>? _slaWarning(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String? ?? 'Open';
    // Resolved tickets no longer need a warning
    if (status == 'Resolved') return null;

    final createdAt = ticket['createdAt'] as Timestamp?;
    final priority = ticket['priority'] as String? ?? 'Medium';
    if (createdAt == null) return null;

    final elapsed =
        DateTime.now().difference(createdAt.toDate()).inMinutes / 60.0;
    final target = _slaHours[priority] ?? 24;

    if (elapsed >= target) {
      return {
        'label': 'SLA Breached',
        'color': const Color(0xFFEF4444),
      };
    } else if (elapsed >= target * 0.75) {
      return {
        'label': 'SLA Warning',
        'color': const Color(0xFFF59E0B),
      };
    }
    return null;
  }

  // ── CSV Export ───────────────────────────────────────────────────────────

  // Feature Added: CSV Export — builds a CSV string from the filtered ticket
  // list and triggers a browser download using dart:html AnchorElement.
  void _exportCsv() {
    if (_lastFilteredTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tickets to export with current filters.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    // CSV header row
    final buffer = StringBuffer();
    buffer.writeln(
      'Ticket ID,Title,Category,Priority,Status,'
      'Created By,Assigned To,Created Date,Last Updated',
    );

    for (final doc in _lastFilteredTickets) {
      final d = doc.data() as Map<String, dynamic>;

      // Escape any commas/quotes inside field values
      String esc(String? v) {
        final s = v ?? '';
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }

      String fmtTs(Timestamp? ts) =>
          ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate()) : '';

      buffer.writeln([
        esc(doc.id),
        esc(d['title'] as String?),
        esc(d['category'] as String?),
        esc(d['priority'] as String?),
        esc(d['status'] as String?),
        esc(d['createdByName'] as String?),
        esc(d['assignedToName'] as String?),
        fmtTs(d['createdAt'] as Timestamp?),
        fmtTs(d['updatedAt'] as Timestamp?),
      ].join(','));
    }

    // Trigger download via a hidden anchor element (Flutter Web only)
    final bytes = Uri.encodeComponent(buffer.toString());
    final filename =
        'tickets_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final anchor = web.HTMLAnchorElement()
      ..href = 'data:text/csv;charset=utf-8,$bytes'
      ..setAttribute('download', filename)
      ..click();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV downloaded'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  // ── Notifications Bell ───────────────────────────────────────────────────

  // Feature Added: Notifications Bell — builds a real-time StreamBuilder
  // badge + popup driven by notifications/{uid}/items in Firestore.
  Widget _buildNotificationsBell(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final unread = snap.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white),
              tooltip: 'Notifications',
              onPressed: () => _showNotificationsPanel(context, uid),
            ),
            // Unread badge — only shown when there are unread notifications
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Shows the notification list in a bottom sheet / dialog
  void _showNotificationsPanel(BuildContext context, String uid) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      // Mark all as read
                      TextButton(
                        onPressed: () => _markAllRead(uid),
                        child: const Text('Mark all read',
                            style: TextStyle(color: Color(0xFF0066FF))),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(uid)
                        .collection('items')
                        .orderBy('createdAt', descending: true)
                        .limit(30)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No notifications yet.',
                              style:
                                  TextStyle(color: Color(0xFF64748B))),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        itemCount: snap.data!.docs.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final doc = snap.data!.docs[i];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final isRead =
                              data['isRead'] as bool? ?? false;
                          final msg =
                              data['message'] as String? ?? '';
                          final ts =
                              data['createdAt'] as Timestamp?;
                          final timeStr = ts != null
                              ? DateFormat('MMM d, h:mm a')
                                  .format(ts.toDate())
                              : '';

                          return ListTile(
                            tileColor: isRead
                                ? null
                                : const Color(0xFFEFF6FF),
                            leading: CircleAvatar(
                              backgroundColor: isRead
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFF0066FF)
                                      .withValues(alpha: 0.1),
                              child: Icon(
                                _notifIcon(
                                    data['type'] as String? ?? ''),
                                size: 18,
                                color: isRead
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0066FF),
                              ),
                            ),
                            title: Text(msg,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600)),
                            subtitle: Text(timeStr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B))),
                            onTap: () {
                              // Mark this notification as read and
                              // navigate to the relevant ticket
                              _markRead(uid, doc.id);
                              final ticketId =
                                  data['ticketId'] as String?;
                              if (ticketId != null &&
                                  ctx.mounted) {
                                Navigator.pop(ctx);
                                Navigator.pushNamed(
                                    context, '/ticket-detail',
                                    arguments: ticketId);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Returns an icon based on notification type string
  IconData _notifIcon(String type) {
    switch (type) {
      case 'status_changed':
        return Icons.swap_horiz_rounded;
      case 'assigned':
        return Icons.person_add_outlined;
      case 'note_added':
        return Icons.note_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _markRead(String uid, String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Engineer Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Feature Added: Analytics navigation button
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Analytics',
            onPressed: () =>
                Navigator.pushNamed(context, '/analytics'),
          ),

          // Feature Added: CSV export button
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),

          // Refresh button (pre-existing)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),

          // Feature Added: Notifications bell with real-time badge
          if (user != null) _buildNotificationsBell(user.uid),

          // Profile popup menu
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<dynamic>(
              icon: const Icon(Icons.account_circle_rounded),
              itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Demo Engineer',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user?.email ?? 'demo@engineer.com',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Support Engineer',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                // Feature Added: Profile navigation (was empty onTap)
                PopupMenuItem(
                  child: const Row(children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ]),
                  onTap: () =>
                      Navigator.pushNamed(context, '/profile'),
                ),
                // Feature Added: Settings navigation (was empty onTap)
                PopupMenuItem(
                  child: const Row(children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ]),
                  onTap: () =>
                      Navigator.pushNamed(context, '/settings'),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryCards()),
          SliverToBoxAdapter(child: _buildFiltersSection(isMobile)),
          _buildTicketsList(isMobile),
        ],
      ),
    );
  }

  // ── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final all = snapshot.data!.docs;

        final openCount = all.where((d) {
          return (d.data() as Map<String, dynamic>)['status'] == 'Open';
        }).length;

        final inProgressCount = all.where((d) {
          return (d.data() as Map<String, dynamic>)['status'] ==
              'In Progress';
        }).length;

        final resolvedToday = all.where((d) {
          final data = d.data() as Map<String, dynamic>;
          if (data['status'] != 'Resolved') return false;
          final ts = data['updatedAt'] as Timestamp?;
          if (ts == null) return false;
          final now = DateTime.now();
          final dt = ts.toDate();
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).length;

        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              final cards = [
                _buildStatCard('Open Tickets', openCount.toString(),
                    Icons.inbox_rounded, const Color(0xFF3B82F6)),
                _buildStatCard('In Progress', inProgressCount.toString(),
                    Icons.timelapse_rounded, const Color(0xFFF59E0B)),
                _buildStatCard('Resolved Today', resolvedToday.toString(),
                    Icons.check_circle_rounded, const Color(0xFF10B981)),
                _buildStatCard('Total Tickets', all.length.toString(),
                    Icons.confirmation_number_rounded,
                    const Color(0xFF8B5CF6)),
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
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 24),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search tickets by title or description...',
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF64748B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF0066FF), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          onChanged: (v) =>
              setState(() => _searchQuery = v.toLowerCase()),
        ),
        const SizedBox(height: 16),

        // Dropdown filters
        if (isMobile)
          Column(children: [
            _buildFilterDropdown(
                'Status', _statuses, _selectedStatus,
                (v) => setState(() => _selectedStatus = v!)),
            const SizedBox(height: 12),
            _buildFilterDropdown(
                'Priority', _priorities, _selectedPriority,
                (v) => setState(() => _selectedPriority = v!)),
            const SizedBox(height: 12),
            _buildFilterDropdown(
                'Category', _categories, _selectedCategory,
                (v) => setState(() => _selectedCategory = v!)),
          ])
        else
          Row(children: [
            Expanded(
              child: _buildFilterDropdown(
                  'Status', _statuses, _selectedStatus,
                  (v) => setState(() => _selectedStatus = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                  'Priority', _priorities, _selectedPriority,
                  (v) => setState(() => _selectedPriority = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                  'Category', _categories, _selectedCategory,
                  (v) => setState(() => _selectedCategory = v!)),
            ),
          ]),
      ]),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    String selected,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
      initialValue: selected,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ── Ticket List ──────────────────────────────────────────────────────────

  Widget _buildTicketsList(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Color(0xFFEF4444)),
                  const SizedBox(height: 16),
                  Text('Error loading tickets: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0066FF)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 80, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  const Text('No tickets yet',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  const Text('New tickets will appear here',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
          );
        }

        // Apply filters
        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (_selectedStatus != 'All' &&
              data['status'] != _selectedStatus) {
            return false;
          }
          if (_selectedPriority != 'All' &&
              data['priority'] != _selectedPriority) {
            return false;
          }
          if (_selectedCategory != 'All' &&
              data['category'] != _selectedCategory) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final title =
                (data['title'] ?? '').toString().toLowerCase();
            final desc =
                (data['description'] ?? '').toString().toLowerCase();
            if (!title.contains(_searchQuery) &&
                !desc.contains(_searchQuery)) {
              return false;
            }
          }
          return true;
        }).toList();

        // Store for CSV export
        _lastFilteredTickets = filtered;

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.filter_list_off,
                      size: 64, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  const Text('No tickets match your filters',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  const Text('Try adjusting your filters',
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = filtered[index];
                final ticket = doc.data() as Map<String, dynamic>;
                return _buildTicketCard(ticket, doc.id, isMobile);
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

  // ── Ticket Card ──────────────────────────────────────────────────────────

  Widget _buildTicketCard(
      Map<String, dynamic> ticket, String ticketId, bool isMobile) {
    final createdAt = ticket['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown';

    // Feature Added: SLA Warning — compute badge for this ticket
    final slaWarn = _slaWarning(ticket);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Feature Added: red border on SLA breached tickets
        side: BorderSide(
          color: slaWarn != null && slaWarn['label'] == 'SLA Breached'
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.08),
          width: slaWarn != null && slaWarn['label'] == 'SLA Breached'
              ? 1.5
              : 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ticket-detail',
            arguments: ticketId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title + status + SLA badge
              Row(children: [
                Expanded(
                  child: Text(
                    ticket['title'] ?? 'Untitled',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(width: 8),
                // Feature Added: SLA warning badge on card
                if (slaWarn != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (slaWarn['color'] as Color)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: (slaWarn['color'] as Color)
                              .withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12,
                          color: slaWarn['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        slaWarn['label'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: slaWarn['color'] as Color),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildStatusBadge(ticket['status'] ?? 'Open'),
              ]),
              const SizedBox(height: 12),

              // Description preview
              Text(
                ticket['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5),
              ),
              const SizedBox(height: 16),

              // Metadata row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _buildPriorityChip(ticket['priority'] ?? 'Medium'),
                      const SizedBox(width: 8),
                      _buildCategoryChip(ticket['category'] ?? 'Other'),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket['createdByName'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                    ]),
                  ],
                )
              else
                Row(children: [
                  _buildPriorityChip(ticket['priority'] ?? 'Medium'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(ticket['category'] ?? 'Other'),
                  const Spacer(),
                  const Icon(Icons.person_outline,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(ticket['createdByName'] ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chip helpers (unchanged, same colours as before) ─────────────────────

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Open':
        bg = const Color(0xFFDCEEFF);
        fg = const Color(0xFF0066FF);
        break;
      case 'In Progress':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFF59E0B);
        break;
      case 'Resolved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF10B981);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'Critical':
        color = const Color(0xFFEF4444);
        break;
      case 'High':
        color = const Color(0xFFF97316);
        break;
      case 'Medium':
        color = const Color(0xFF3B82F6);
        break;
      case 'Low':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.flag, size: 12, color: color),
        const SizedBox(width: 4),
        Text(priority,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.category_outlined,
            size: 12, color: Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(category,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
      ]),
    );
  }
}
