import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENGINEER DASHBOARD - Real-time Ticket Management
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
  final List<String> _priorities = ['All', 'Critical', 'High', 'Medium', 'Low'];
  final List<String> _categories = [
    'All',
    'Network Issues',
    'Software Problems',
    'Hardware Issues',
    'Account & Access',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {}); // Refresh the stream
            },
            tooltip: 'Refresh',
          ),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user?.email ?? 'demo@engineer.com',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Support Engineer',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                  onTap: () {},
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Sign Out'),
                    ],
                  ),
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
          // Summary Cards
          SliverToBoxAdapter(child: _buildSummaryCards()),

          // Filters
          SliverToBoxAdapter(child: _buildFiltersSection(isMobile)),

          // Tickets List
          _buildTicketsList(isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  // Summary Cards showing ticket statistics
  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final allTickets = snapshot.data!.docs;
        final openTickets = allTickets.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Open';
        }).length;

        final inProgressTickets = allTickets.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'In Progress';
        }).length;

        final resolvedToday = allTickets.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] != 'Resolved') return false;

          final updatedAt = data['updatedAt'] as Timestamp?;
          if (updatedAt == null) return false;

          final now = DateTime.now();
          final ticketDate = updatedAt.toDate();
          return ticketDate.year == now.year &&
              ticketDate.month == now.month &&
              ticketDate.day == now.day;
        }).length;

        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Open',
                            openTickets.toString(),
                            Icons.inbox_rounded,
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'In Progress',
                            inProgressTickets.toString(),
                            Icons.timelapse_rounded,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Resolved Today',
                            resolvedToday.toString(),
                            Icons.check_circle_rounded,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            allTickets.length.toString(),
                            Icons.confirmation_number_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Open Tickets',
                      openTickets.toString(),
                      Icons.inbox_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'In Progress',
                      inProgressTickets.toString(),
                      Icons.timelapse_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Resolved Today',
                      resolvedToday.toString(),
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Tickets',
                      allTickets.length.toString(),
                      Icons.confirmation_number_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Filters Section
  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tickets by title or description...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0066FF),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),

          // Filter Dropdowns
          if (isMobile)
            Column(
              children: [
                _buildFilterDropdown('Status', _statuses, _selectedStatus, (
                  value,
                ) {
                  setState(() => _selectedStatus = value!);
                }),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  'Priority',
                  _priorities,
                  _selectedPriority,
                  (value) {
                    setState(() => _selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  'Category',
                  _categories,
                  _selectedCategory,
                  (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Status',
                    _statuses,
                    _selectedStatus,
                    (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Priority',
                    _priorities,
                    _selectedPriority,
                    (value) {
                      setState(() => _selectedPriority = value!);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Category',
                    _categories,
                    _selectedCategory,
                    (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    String selectedValue,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      value: selectedValue,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Tickets List with Real-time Updates
  Widget _buildTicketsList(bool isMobile, bool isTablet, bool isDesktop) {
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
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tickets',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    size: 80,
                    color: Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tickets yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'New tickets will appear here',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        // Apply filters
        var filteredTickets = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Status filter
          if (_selectedStatus != 'All' && data['status'] != _selectedStatus) {
            return false;
          }

          // Priority filter
          if (_selectedPriority != 'All' &&
              data['priority'] != _selectedPriority) {
            return false;
          }

          // Category filter
          if (_selectedCategory != 'All' &&
              data['category'] != _selectedCategory) {
            return false;
          }

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '')
                .toString()
                .toLowerCase();
            if (!title.contains(_searchQuery) &&
                !description.contains(_searchQuery)) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filteredTickets.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tickets match your filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adjusting your filters',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final doc = filteredTickets[index];
              final ticket = doc.data() as Map<String, dynamic>;
              final ticketId = doc.id;

              return _buildTicketCard(ticket, ticketId, isMobile);
            }, childCount: filteredTickets.length),
          ),
        );
      },
    );
  }

  // Individual Ticket Card
  Widget _buildTicketCard(
    Map<String, dynamic> ticket,
    String ticketId,
    bool isMobile,
  ) {
    final createdAt = ticket['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/ticket-detail', arguments: ticketId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(ticket['status'] ?? 'Open'),
                ],
              ),
              const SizedBox(height: 12),

              // Description Preview
              Text(
                ticket['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Metadata Row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPriorityChip(ticket['priority'] ?? 'Medium'),
                        const SizedBox(width: 8),
                        _buildCategoryChip(ticket['category'] ?? 'Other'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ticket['createdByName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildPriorityChip(ticket['priority'] ?? 'Medium'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(ticket['category'] ?? 'Other'),
                    const Spacer(),
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket['createdByName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Status Badge
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Open':
        bgColor = const Color(0xFFDCEEFF);
        textColor = const Color(0xFF0066FF);
        break;
      case 'In Progress':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFF59E0B);
        break;
      case 'Resolved':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF10B981);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Priority Chip
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Category Chip
  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 12,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
