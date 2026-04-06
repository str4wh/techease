import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MY TICKETS PAGE — Shows all tickets submitted by the currently logged-in
// user, with real-time updates and status filtering.
// Accessible from the "My Tickets" link in the top nav and mobile drawer
// on both the user dashboard and the create-ticket page.
// ═══════════════════════════════════════════════════════════════════════════
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final _user = FirebaseAuth.instance.currentUser;

  // Active status filter — 'All' shows every ticket
  String _selectedStatus = 'All';
  final List<String> _statuses = [
    'All', 'Open', 'In Progress', 'Resolved'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text(
          'My Tickets',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          // Quick link to create a new ticket
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/create-ticket'),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text(
              'New Ticket',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status filter bar ──────────────────────────────────────────
          _buildStatusFilterBar(),

          // ── Ticket list ────────────────────────────────────────────────
          Expanded(child: _buildTicketList(isMobile)),
        ],
      ),
    );
  }

  // Horizontal chip-strip filter for Open / In Progress / Resolved / All
  Widget _buildStatusFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses.map((status) {
            final isSelected = _selectedStatus == status;

            // Colour each status differently
            Color chipColor;
            switch (status) {
              case 'Open':
                chipColor = const Color(0xFF3B82F6);
                break;
              case 'In Progress':
                chipColor = const Color(0xFFF59E0B);
                break;
              case 'Resolved':
                chipColor = const Color(0xFF10B981);
                break;
              default:
                chipColor = const Color(0xFF0066FF);
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedStatus = status),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? chipColor
                        : chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: chipColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : chipColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Real-time ticket list filtered to the current user and selected status
  Widget _buildTicketList(bool isMobile) {
    // Query only this user's tickets, sorted newest first
    var query = FirebaseFirestore.instance
        .collection('tickets')
        .where('createdBy', isEqualTo: _user?.uid)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0066FF)),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 12),
                Text(
                  'Could not load tickets.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        // Apply status filter client-side (avoids a composite Firestore index)
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          if (_selectedStatus == 'All') return true;
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == _selectedStatus;
        }).toList();

        // Empty state
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 72, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                Text(
                  _selectedStatus == 'All'
                      ? 'No tickets yet'
                      : 'No $_selectedStatus tickets',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedStatus == 'All'
                      ? 'Tap "+ New Ticket" to submit your first one.'
                      : 'Try selecting a different status filter.',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_selectedStatus == 'All')
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/create-ticket'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          );
        }

        // Ticket cards
        return ListView.builder(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTicketCard(doc.id, data, isMobile);
          },
        );
      },
    );
  }

  // Individual ticket card — tapping navigates to ticket detail
  Widget _buildTicketCard(
      String ticketId, Map<String, dynamic> data, bool isMobile) {
    final status = data['status'] as String? ?? 'Open';
    final priority = data['priority'] as String? ?? 'Medium';
    final category = data['category'] as String? ?? 'Other';
    final createdAt = data['createdAt'] as Timestamp?;

    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
        : 'Unknown date';

    // Status colour
    Color statusBg, statusFg;
    switch (status) {
      case 'Open':
        statusBg = const Color(0xFFDCEEFF);
        statusFg = const Color(0xFF0066FF);
        break;
      case 'In Progress':
        statusBg = const Color(0xFFFEF3C7);
        statusFg = const Color(0xFFF59E0B);
        break;
      case 'Resolved':
        statusBg = const Color(0xFFD1FAE5);
        statusFg = const Color(0xFF10B981);
        break;
      default:
        statusBg = const Color(0xFFF3F4F6);
        statusFg = const Color(0xFF6B7280);
    }

    // Priority colour
    Color priorityColor;
    switch (priority) {
      case 'Critical':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'High':
        priorityColor = const Color(0xFFF97316);
        break;
      case 'Medium':
        priorityColor = const Color(0xFF3B82F6);
        break;
      default:
        priorityColor = const Color(0xFF10B981);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/ticket-detail',
          arguments: ticketId,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status badge
              Row(children: [
                Expanded(
                  child: Text(
                    data['title'] as String? ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusFg,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // Description preview
              Text(
                data['description'] as String? ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.5),
              ),
              const SizedBox(height: 12),

              // Metadata row
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  // Priority chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color:
                              priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.flag, size: 11, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(priority,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: priorityColor)),
                    ]),
                  ),

                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(category,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ),

                  // Date
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.access_time,
                        size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(formattedDate,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
