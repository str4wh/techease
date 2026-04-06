import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TICKET DETAIL PAGE — Features Added:
//   • Status Update Controls  — engineers can change status via a dropdown
//     without having to add a note (previously only auto-set on note add).
//   • Ticket Assignment        — "Assign to Me" button + dropdown to assign
//     any engineer from the users collection.
//   • SLA Elapsed Time Display — header shows time since creation, with
//     colour-coding against priority SLA targets (Critical 4h, High 8h,
//     Medium 24h, Low 72h).
//   • File Attachment Display  — shows attachments stored in the ticket's
//     `attachments` array (URLs written by create_ticket_page).
//   • Notification write-back  — when status changes or a note is added a
//     notification document is written to the ticket creator's notifications
//     subcollection so the bell badge updates in real time.
// ═══════════════════════════════════════════════════════════════════════════
class TicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _noteController = TextEditingController();

  // Loading / saving flags
  bool _isAddingNote = false;
  bool _isUpdatingStatus = false;
  bool _isAssigning = false;

  // Role of the currently logged-in user — loaded once on init
  String _currentUserRole = 'user';

  // List of engineers fetched from Firestore for the assignment dropdown
  List<Map<String, dynamic>> _engineers = [];

  // SLA target hours indexed by priority name
  static const Map<String, int> _slaHours = {
    'Critical': 4,
    'High': 8,
    'Medium': 24,
    'Low': 72,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadEngineers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Determine whether the logged-in user is an engineer
  Future<void> _loadCurrentUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _currentUserRole = doc.data()?['role'] as String? ?? 'user';
        });
      }
    } catch (_) {}
  }

  // Fetch all engineers so the assignment dropdown can list them
  Future<void> _loadEngineers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'engineer')
          .get();
      if (mounted) {
        setState(() {
          _engineers = snap.docs
              .map((d) => {
                    'uid': d.id,
                    'name': d.data()['name'] as String? ?? 'Engineer',
                    'email': d.data()['email'] as String? ?? '',
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      return DateFormat('MMMM d, yyyy').format(timestamp.toDate());
    }
    return 'Unknown';
  }

  // Returns a human-friendly elapsed-time string and a colour
  // based on whether the ticket has breached its SLA target
  Map<String, dynamic> _slaInfo(
      Timestamp? createdAt, String priority, String status) {
    if (createdAt == null) {
      return {'label': 'Unknown age', 'color': const Color(0xFF64748B)};
    }

    final elapsed = DateTime.now().difference(createdAt.toDate());
    final totalMinutes = elapsed.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    String label;
    if (hours > 0) {
      label = '${hours}h ${minutes}m elapsed';
    } else {
      label = '${minutes}m elapsed';
    }

    // Resolved tickets are always shown in green — SLA no longer relevant
    if (status == 'Resolved') {
      return {'label': label, 'color': const Color(0xFF10B981)};
    }

    final target = _slaHours[priority] ?? 24;
    final elapsedHours = elapsed.inMinutes / 60.0;

    Color color;
    if (elapsedHours >= target) {
      // Breached SLA
      color = const Color(0xFFEF4444);
    } else if (elapsedHours >= target * 0.75) {
      // Within 25% of SLA deadline — warn in amber
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFF10B981);
    }

    return {'label': label, 'color': color};
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  // Feature Added: Status Update Controls — engineer-only status change
  Future<void> _updateStatus(
      String newStatus, String ticketTitle, String createdById) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([
          {
            'action': 'Status changed to $newStatus',
            'by': _currentUser?.displayName ?? 'Engineer',
            'timestamp': Timestamp.fromDate(DateTime.now()),
          },
        ]),
      });

      // Write a notification to the ticket creator so their bell updates
      await _writeNotification(
        userId: createdById,
        message: 'Your ticket "$ticketTitle" is now $newStatus',
        ticketId: widget.ticketId,
        type: 'status_changed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  // Feature Added: Assignment — assign ticket to a selected engineer
  Future<void> _assignTicket(
    Map<String, dynamic> engineer,
    String ticketTitle,
  ) async {
    if (_isAssigning) return;
    setState(() => _isAssigning = true);

    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
        'assignedTo': engineer['uid'],
        'assignedToName': engineer['name'],
        'updatedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([
          {
            'action':
                'Assigned to ${engineer['name']}',
            'by': _currentUser?.displayName ?? 'Engineer',
            'timestamp': Timestamp.fromDate(DateTime.now()),
          },
        ]),
      });

      // Notify the assigned engineer
      await _writeNotification(
        userId: engineer['uid'] as String,
        message: 'You have been assigned ticket "$ticketTitle"',
        ticketId: widget.ticketId,
        type: 'assigned',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket assigned to ${engineer['name']}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning ticket: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  // Adds a note to the ticket timeline without forcing status to Resolved
  Future<void> _addNote(
      String ticketTitle, String createdById) async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _isAddingNote = true);

    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
        'timeline': FieldValue.arrayUnion([
          {
            'action': 'Note: ${_noteController.text.trim()}',
            'by': _currentUser?.displayName ?? 'User',
            'timestamp': Timestamp.fromDate(DateTime.now()),
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the ticket creator about the new note
      await _writeNotification(
        userId: createdById,
        message:
            'A note was added to your ticket "$ticketTitle"',
        ticketId: widget.ticketId,
        type: 'note_added',
      );

      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added'),
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
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  // Feature Added: Notification write-back — writes to
  // notifications/{userId}/items so the bell badge stays in sync
  Future<void> _writeNotification({
    required String userId,
    required String message,
    required String ticketId,
    required String type,
  }) async {
    // Don't notify yourself
    if (userId == _currentUser?.uid) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
        'message': message,
        'ticketId': ticketId,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification failure must never block the primary action
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0066FF)),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Ticket not found'));
            }

            final ticket = snapshot.data!.data() as Map<String, dynamic>;
            final createdById = ticket['createdBy'] as String? ?? '';
            final ticketTitle = ticket['title'] as String? ?? 'Ticket';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ticket, isMobile),
                  Padding(
                    padding: EdgeInsets.all(
                      isMobile ? 16 : (isTablet ? 24 : 32),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainContent(
                                  ticket, isMobile, ticketTitle, createdById),
                              const SizedBox(height: 24),
                              _buildDetailsSidebar(
                                  ticket, ticketTitle, createdById),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildMainContent(ticket, isMobile,
                                    ticketTitle, createdById),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildDetailsSidebar(
                                    ticket, ticketTitle, createdById),
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

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, Map<String, dynamic> ticket, bool isMobile) {
    final status = ticket['status'] as String? ?? 'Open';
    final priority = ticket['priority'] as String? ?? 'Medium';
    final category = ticket['category'] as String? ?? 'Uncategorized';
    final createdAt = ticket['createdAt'] as Timestamp?;

    // Feature Added: SLA elapsed time in header
    final sla = _slaInfo(createdAt, priority, status);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom:
              BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  try {
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser?.uid)
                        .get();
                    final role = doc.data()?['role'] as String?;
                    if (context.mounted) {
                      if (role == 'engineer') {
                        Navigator.pushReplacementNamed(
                            context, '/engineer-dashboard');
                      } else {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    }
                  } catch (_) {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  }
                },
                color: const Color(0xFF1A1A1A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // Status badge
              _buildBadge(
                status,
                status == 'Open'
                    ? const Color(0xFF0066FF)
                    : status == 'In Progress'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
              ),
              // Priority badge
              _buildBadge(
                '↑ $priority',
                _getPriorityColor(priority),
              ),
              // Category + date
              Text(
                '$category  •  Created ${_formatDate(ticket['createdAt'])}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Feature Added: SLA elapsed time indicator
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 15,
                color: sla['color'] as Color,
              ),
              const SizedBox(width: 6),
              Text(
                sla['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sla['color'] as Color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(SLA target: ${_slaHours[priority] ?? 24}h)',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B)),
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
        color: color.withValues(alpha: 0.1),
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

  // ── Main Content Column ──────────────────────────────────────────────────

  Widget _buildMainContent(Map<String, dynamic> ticket, bool isMobile,
      String ticketTitle, String createdById) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description card
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Description',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              Text(
                ticket['description'] ?? 'No description provided',
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF1A1A1A), height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Feature Added: File Attachments Display
        if ((ticket['attachments'] as List?)?.isNotEmpty == true)
          _buildAttachmentsCard(ticket['attachments'] as List),
        if ((ticket['attachments'] as List?)?.isNotEmpty == true)
          const SizedBox(height: 20),

        // AI Solutions card (if present)
        if (ticket['aiSolutions'] != null)
          _buildAiCard(ticket),
        if (ticket['aiSolutions'] != null) const SizedBox(height: 20),

        // Feature Added: Status Update Controls (engineers only)
        if (_currentUserRole == 'engineer')
          _buildStatusUpdateCard(ticket, ticketTitle, createdById),
        if (_currentUserRole == 'engineer') const SizedBox(height: 20),

        // Timeline card
        _buildTimelineCard(ticket),
        const SizedBox(height: 20),

        // Add Note card
        _buildAddNoteCard(ticketTitle, createdById),
      ],
    );
  }

  // Feature Added: File Attachments Display
  Widget _buildAttachmentsCard(List attachments) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 18, color: Color(0xFF0066FF)),
              SizedBox(width: 8),
              Text('Attachments',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          // Display each attachment as a tappable chip with filename
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((att) {
              final url = att['url'] as String? ?? '';
              final name = att['name'] as String? ?? 'Attachment';
              return InkWell(
                onTap: () {
                  // Show the URL in a dialog so the user can open it
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(name),
                      content: SelectableText(url),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF0066FF)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          size: 16, color: Color(0xFF0066FF)),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0066FF),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // AI solutions card (pre-existing, kept for continuity)
  Widget _buildAiCard(Map<String, dynamic> ticket) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 16, color: Color(0xFF0066FF)),
              ),
              const SizedBox(width: 10),
              const Text('AI Recommendations',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          if (ticket['aiSolutions'] != null)
            _buildAiSection(
                'Recommended Solutions', ticket['aiSolutions'] as String),
          if (ticket['aiNextSteps'] != null) ...[
            const SizedBox(height: 12),
            _buildAiSection(
                'Next Steps', ticket['aiNextSteps'] as String),
          ],
          if (ticket['aiEstimatedTime'] != null) ...[
            const SizedBox(height: 12),
            _buildAiSection(
                'Estimated Time', ticket['aiEstimatedTime'] as String),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSection(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        Text(content,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF1A1A1A), height: 1.5)),
      ],
    );
  }

  // Feature Added: Status Update Controls — dropdown for engineers
  Widget _buildStatusUpdateCard(Map<String, dynamic> ticket,
      String ticketTitle, String createdById) {
    final currentStatus = ticket['status'] as String? ?? 'Open';
    const statuses = ['Open', 'In Progress', 'Resolved'];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0066FF)),
              SizedBox(width: 8),
              Text('Update Status',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented status buttons
          Row(
            children: statuses.map((s) {
              final isSelected = currentStatus == s;
              Color statusColor;
              switch (s) {
                case 'Open':
                  statusColor = const Color(0xFF3B82F6);
                  break;
                case 'In Progress':
                  statusColor = const Color(0xFFF59E0B);
                  break;
                default:
                  statusColor = const Color(0xFF10B981);
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: (isSelected || _isUpdatingStatus)
                        ? null
                        : () => _updateStatus(
                            s, ticketTitle, createdById),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? statusColor
                          : statusColor.withValues(alpha: 0.1),
                      foregroundColor:
                          isSelected ? Colors.white : statusColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: _isUpdatingStatus
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  isSelected ? Colors.white : statusColor,
                            ),
                          )
                        : Text(s,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Timeline card (pre-existing, unchanged)
  Widget _buildTimelineCard(Map<String, dynamic> ticket) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 20),
          if (ticket['timeline'] != null)
            ...((ticket['timeline'] as List).map((entry) {
              return _buildTimelineEntry(
                entry['by'] ?? 'Unknown',
                entry['action'] ?? '',
                entry['timestamp'],
              );
            })),
          if ((ticket['timeline'] as List?)?.isEmpty ?? true)
            const Text('No activity yet.',
                style:
                    TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(
      String person, String action, dynamic timestamp) {
    String timeString = 'Just now';
    if (timestamp != null && timestamp is Timestamp) {
      timeString =
          DateFormat('MMM d, yyyy, h:mm a').format(timestamp.toDate());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              action.contains('created')
                  ? Icons.add_circle_outline
                  : action.contains('Assigned')
                      ? Icons.person_outline
                      : action.contains('Note')
                          ? Icons.note_outlined
                          : action.contains('Status')
                              ? Icons.swap_horiz_rounded
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
                        color: Color(0xFF1A1A1A)),
                    children: [
                      TextSpan(
                        text: '  —  $timeString',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(action,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add Note card (note no longer auto-resolves the ticket)
  Widget _buildAddNoteCard(String ticketTitle, String createdById) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a Note',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
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
                    color: Color(0xFF0066FF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isAddingNote
                ? null
                : () => _addNote(ticketTitle, createdById),
            icon: _isAddingNote
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.send, size: 18),
            label: const Text('Send Note'),
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

  // ── Details Sidebar ──────────────────────────────────────────────────────

  Widget _buildDetailsSidebar(Map<String, dynamic> ticket,
      String ticketTitle, String createdById) {
    return Column(
      children: [
        // Details card
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 24),
              _buildDetailItem(
                  'Created By',
                  ticket['createdByName'] ?? 'Unknown',
                  Icons.person),
              const SizedBox(height: 20),
              _buildDetailItem(
                  'Assigned To',
                  ticket['assignedToName'] ?? 'Unassigned',
                  Icons.person_outline),
              const SizedBox(height: 20),
              _buildDetailItem(
                  'Created', _formatDate(ticket['createdAt']),
                  Icons.calendar_today),
              const SizedBox(height: 20),
              _buildDetailItem(
                  'Last Updated', _formatDate(ticket['updatedAt']),
                  Icons.update),
            ],
          ),
        ),

        // Feature Added: Assignment Controls (engineers only)
        if (_currentUserRole == 'engineer') ...[
          const SizedBox(height: 20),
          _buildAssignmentCard(ticket, ticketTitle),
        ],
      ],
    );
  }

  // Feature Added: Assignment Card — "Assign to Me" + engineer dropdown
  Widget _buildAssignmentCard(
      Map<String, dynamic> ticket, String ticketTitle) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_ind_outlined,
                  size: 18, color: Color(0xFF0066FF)),
              SizedBox(width: 8),
              Text('Assignment',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),

          // "Assign to Me" quick button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAssigning
                  ? null
                  : () => _assignTicket(
                        {
                          'uid': _currentUser?.uid ?? '',
                          'name':
                              _currentUser?.displayName ?? 'Engineer',
                        },
                        ticketTitle,
                      ),
              icon: const Icon(Icons.person_add_alt_1_outlined,
                  size: 16),
              label: const Text('Assign to Me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Assign to any engineer via dropdown
          if (_engineers.isNotEmpty) ...[
            const Text(
              'Or assign to:',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF0066FF), width: 2),
                ),
              ),
              hint: const Text('Select engineer',
                  style: TextStyle(fontSize: 13)),
              initialValue: ticket['assignedTo'] as String?,
              items: _engineers.map((e) {
                return DropdownMenuItem<String>(
                  value: e['uid'] as String,
                  child: Text(e['name'] as String,
                      style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: _isAssigning
                  ? null
                  : (uid) {
                      if (uid == null) return;
                      final eng = _engineers.firstWhere(
                          (e) => e['uid'] == uid,
                          orElse: () => {});
                      if (eng.isNotEmpty) {
                        _assignTicket(eng, ticketTitle);
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  const Color(0xFF0066FF).withValues(alpha: 0.1),
              child: Icon(icon, size: 18, color: const Color(0xFF0066FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A))),
            ),
          ],
        ),
      ],
    );
  }

  // Shared card container (white, rounded, subtle shadow)
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: child,
    );
  }
}
