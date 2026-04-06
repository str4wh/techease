import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE — Feature Added: in-app notification toggles and SLA
// reminder preference.  Preferences are persisted inside the Firestore
// users/{uid} document under a nested "settings" map so they survive
// sessions and are available on every device the user logs in from.
// ═══════════════════════════════════════════════════════════════════════════
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _feedbackMessage;
  bool _feedbackIsSuccess = true;

  // ── Notification preference toggles ────────────────────────────────────
  // Each maps to a key inside users/{uid}/settings in Firestore

  // Receive an in-app notification when a ticket assigned to you is updated
  bool _notifyOnTicketUpdate = true;

  // Receive a notification when a new ticket is submitted (engineers only)
  bool _notifyOnNewTicket = true;

  // Receive a notification when someone adds a note to your ticket
  bool _notifyOnNote = true;

  // Show a visual SLA warning badge on tickets approaching their deadline
  bool _slaWarningsEnabled = true;

  // Role — needed to decide which settings to show
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Pull saved preferences from Firestore
  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'] as String? ?? 'user';

        // Load preferences from the nested 'settings' map; fall back to
        // defaults if the sub-map doesn't exist yet (first time visiting)
        final settings =
            data['settings'] as Map<String, dynamic>? ?? {};
        setState(() {
          _notifyOnTicketUpdate =
              settings['notifyOnTicketUpdate'] as bool? ?? true;
          _notifyOnNewTicket =
              settings['notifyOnNewTicket'] as bool? ?? true;
          _notifyOnNote = settings['notifyOnNote'] as bool? ?? true;
          _slaWarningsEnabled =
              settings['slaWarningsEnabled'] as bool? ?? true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Failed to load settings: $e';
        _feedbackIsSuccess = false;
        _isLoading = false;
      });
    }
  }

  // Persist all toggles to Firestore under users/{uid}.settings
  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'settings': {
          'notifyOnTicketUpdate': _notifyOnTicketUpdate,
          'notifyOnNewTicket': _notifyOnNewTicket,
          'notifyOnNote': _notifyOnNote,
          'slaWarningsEnabled': _slaWarningsEnabled,
        },
      });

      if (mounted) {
        setState(() {
          _feedbackMessage = 'Settings saved.';
          _feedbackIsSuccess = true;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Failed to save settings: $e';
          _feedbackIsSuccess = false;
          _isSaving = false;
        });
      }
    }
  }

  // Navigate back to the correct dashboard for this user's role
  Future<void> _goBack() async {
    if (_role == 'engineer') {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/engineer-dashboard');
      }
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your notifications and display options.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Feedback banner
                      if (_feedbackMessage != null)
                        _buildBanner(
                          _feedbackMessage!,
                          _feedbackIsSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          _feedbackIsSuccess,
                        ),

                      // ── Notification section ─────────────────────────
                      _buildSectionCard(
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        children: [
                          _buildToggle(
                            label: 'Ticket status updates',
                            subtitle:
                                'Notify when a ticket you submitted changes status',
                            value: _notifyOnTicketUpdate,
                            onChanged: (v) =>
                                setState(() => _notifyOnTicketUpdate = v),
                          ),
                          const Divider(height: 1),
                          _buildToggle(
                            label: 'New ticket submitted',
                            subtitle: _role == 'engineer'
                                ? 'Notify when a new ticket arrives in the queue'
                                : 'Show when a ticket you own is picked up',
                            value: _notifyOnNewTicket,
                            onChanged: (v) =>
                                setState(() => _notifyOnNewTicket = v),
                          ),
                          const Divider(height: 1),
                          _buildToggle(
                            label: 'Notes & comments',
                            subtitle:
                                'Notify when a note is added to your ticket',
                            value: _notifyOnNote,
                            onChanged: (v) =>
                                setState(() => _notifyOnNote = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── SLA / display section ────────────────────────
                      _buildSectionCard(
                        title: 'Display',
                        icon: Icons.tune_outlined,
                        children: [
                          _buildToggle(
                            label: 'SLA warning badges',
                            subtitle:
                                'Highlight tickets that are approaching or past their SLA deadline',
                            value: _slaWarningsEnabled,
                            onChanged: (v) =>
                                setState(() => _slaWarningsEnabled = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Settings',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Card wrapper for a settings section with title + icon
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0066FF)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Toggle rows
          ...children,
        ],
      ),
    );
  }

  // Single toggle row with label + subtitle
  Widget _buildToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF0066FF),
            activeTrackColor: const Color(0xFF0066FF).withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // Banner for success / error feedback
  Widget _buildBanner(String message, Color color, bool isSuccess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
