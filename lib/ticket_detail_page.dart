import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TICKET DETAIL PAGE - View and Manage Individual Ticket
// ═══════════════════════════════════════════════════════════════════════════
class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tickets')
              .doc(widget.ticketId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Ticket not found'));
            }

            final ticket = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, ticket, isMobile),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(
                      isMobile ? 16 : (isTablet ? 24 : 32),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainContent(ticket, isMobile),
                              const SizedBox(height: 24),
                              _buildDetailsSidebar(ticket),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildMainContent(ticket, isMobile),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildDetailsSidebar(ticket),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> ticket,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                color: const Color(0xFF1A1A1A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Badges and metadata
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildBadge(
                ticket['status'] ?? 'Open',
                ticket['status'] == 'Open'
                    ? const Color(0xFF0066FF)
                    : ticket['status'] == 'In Progress'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
              _buildBadge(
                '↑ ${ticket['priority'] ?? 'Medium'}',
                _getPriorityColor(ticket['priority'] ?? 'Medium'),
              ),
              Text(
                '${ticket['category'] ?? 'Uncategorized'} • Created ${_formatDate(ticket['createdAt'])}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFF0066FF);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildMainContent(Map<String, dynamic> ticket, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ticket['description'] ?? 'No description provided',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Timeline Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              // Timeline entries
              if (ticket['timeline'] != null)
                ...((ticket['timeline'] as List).map((entry) {
                  return _buildTimelineEntry(
                    entry['by'] ?? 'Unknown',
                    entry['action'] ?? 'Action',
                    entry['timestamp'],
                  );
                })),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Add Note Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isAddingNote ? null : _addNote,
                icon: _isAddingNote
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Send Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEntry(String person, String action, dynamic timestamp) {
    String timeString = 'Just now';
    if (timestamp != null && timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      timeString = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              action.contains('created')
                  ? Icons.add_circle_outline
                  : action.contains('Assigned')
                  ? Icons.person_outline
                  : action.contains('note')
                  ? Icons.note_outlined
                  : Icons.access_time,
              size: 20,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: person,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    children: [
                      TextSpan(
                        text: ' - $timeString',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSidebar(Map<String, dynamic> ticket) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          // Created By
          _buildDetailItem(
            'Created By',
            ticket['createdByName'] ?? 'Unknown',
            Icons.person,
          ),
          const SizedBox(height: 20),
          // Assigned To
          _buildDetailItem(
            'Assigned To',
            ticket['assignedToName'] ?? 'Unassigned',
            Icons.person_outline,
          ),
          const SizedBox(height: 20),
          // Created
          _buildDetailItem(
            'Created',
            _formatDate(ticket['createdAt']),
            Icons.calendar_today,
          ),
          const SizedBox(height: 20),
          // Last Updated
          _buildDetailItem(
            'Last Updated',
            _formatDate(ticket['updatedAt']),
            Icons.update,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0066FF).withOpacity(0.1),
              child: Icon(icon, size: 18, color: const Color(0xFF0066FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('MMMM d, yyyy').format(dateTime);
    }
    return 'Unknown';
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() {
      _isAddingNote = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
            'timeline': FieldValue.arrayUnion([
              {
                'action': 'Added note: ${_noteController.text}',
                'by': user?.displayName ?? 'Unknown User',
                'timestamp': Timestamp.fromDate(DateTime.now()),
              },
            ]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding note: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingNote = false;
        });
      }
    }
  }
}
