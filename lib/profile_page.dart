import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE PAGE — Feature Added: displays and allows editing of the user's
// display name.  Email is shown read-only (managed by Firebase Auth).
// Role is shown read-only.  On save, both Firebase Auth and the Firestore
// users/{uid} document are updated to keep them in sync.
// ═══════════════════════════════════════════════════════════════════════════
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Loaded from Firestore
  String _role = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load current profile data from Firebase Auth + Firestore
  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Prefill display name from Firebase Auth
      _nameController.text = user.displayName ?? '';

      // Fetch role from Firestore users collection
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _role = doc.data()?['role'] as String? ?? 'user';
          _isLoading = false;
        });
      } else {
        setState(() {
          _role = 'user';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  // Save updated display name to Firebase Auth and Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final newName = _nameController.text.trim();

      // Update Firebase Auth display name
      await user.updateDisplayName(newName);

      // Update Firestore users document to keep it in sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': newName});

      if (mounted) {
        setState(() {
          _successMessage = 'Profile updated successfully.';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save profile: $e';
          _isSaving = false;
        });
      }
    }
  }

  // Navigate back to the appropriate dashboard based on user role
  Future<void> _goBack() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    if (_role == 'engineer') {
      if (mounted) Navigator.pushReplacementNamed(context, '/engineer-dashboard');
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
                      // ── Avatar + name header ───────────────────────────
                      Center(
                        child: Column(
                          children: [
                            // Initials avatar
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFF0066FF),
                              child: Text(
                                (user?.displayName ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066FF)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _role == 'engineer'
                                    ? 'Support Engineer'
                                    : 'End User',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Feedback banners ──────────────────────────────
                      if (_successMessage != null)
                        _buildBanner(
                            _successMessage!, const Color(0xFF10B981), true),
                      if (_errorMessage != null)
                        _buildBanner(
                            _errorMessage!, const Color(0xFFEF4444), false),

                      // ── Edit form ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Display name — editable
                              _buildLabel('Full Name'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration(
                                    'Enter your full name',
                                    Icons.person_outline),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Name is required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Email — read-only
                              _buildLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: user?.email ?? '',
                                readOnly: true,
                                decoration: _inputDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ).copyWith(
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  helperText: 'Email cannot be changed here',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Role — read-only
                              _buildLabel('Role'),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _role == 'engineer'
                                    ? 'Support Engineer'
                                    : 'End User',
                                readOnly: true,
                                decoration: _inputDecoration(
                                  'Role',
                                  Icons.badge_outlined,
                                ).copyWith(
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  helperText:
                                      'Role is assigned at registration',
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
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
                                          'Save Changes',
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

                      const SizedBox(height: 20),

                      // ── Sign out button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Color(0xFFEF4444)),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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

  // Shared label text style
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  // Consistent InputDecoration reusing the project's existing border style
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
