import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUTHENTICATION PAGE - Combined Sign In & Sign Up
// ═══════════════════════════════════════════════════════════════════════════
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Toggle between sign-up and sign-in modes
  bool isSignUp = true;
  bool _hasInitialized = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI state
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _selectedRole; // Store selected role: 'user' or 'engineer'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle route arguments to set initial mode
    if (!_hasInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['mode'] != null) {
        setState(() {
          isSignUp = args['mode'] == 'signup';
        });
      }
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (isSignUp && value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Name validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Handle authentication (Sign Up or Sign In)
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate role selection for sign up
    if (isSignUp && _selectedRole == null) {
      setState(() {
        _errorMessage = 'Please select your role';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isSignUp) {
        // Sign Up flow
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Passwords do not match';
          });
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Update display name
        await userCredential.user?.updateDisplayName(
          _nameController.text.trim(),
        );
        await userCredential.user?.reload();

        // Store user data including role in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole, // 'user' or 'engineer'
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          // Navigate based on selected role
          if (_selectedRole == 'engineer') {
            Navigator.pushReplacementNamed(context, '/engineer-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } else {
        // Sign In flow
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Fetch user role from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (mounted) {
          // Navigate based on stored role
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final role = userData['role'] as String?;

            if (role == 'engineer') {
              Navigator.pushReplacementNamed(context, '/engineer-dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          } else {
            // Default to user dashboard if role not found
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'weak-password':
            _errorMessage = 'Password is too weak. Use a stronger password.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'An account with this email already exists.';
            break;
          case 'user-not-found':
            _errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            _errorMessage = 'Invalid email address format.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Too many attempts. Please try again later.';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Authentication is currently disabled.';
            break;
          default:
            _errorMessage = 'Authentication failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  // Toggle between Sign Up and Sign In
  void _toggleAuthMode() {
    setState(() {
      isSignUp = !isSignUp;
      _errorMessage = null;
      _selectedRole = null; // Clear selected role
      // Clear form when switching modes
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: isMobile ? 24 : 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back to Home Button (Top Left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    label: const Text(
                      'Back to home',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Page Heading
                Text(
                  isSignUp ? 'Create an Account' : 'Sign In',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Page Subtitle
                Text(
                  isSignUp
                      ? 'Join IT Helpdesk and streamline your support'
                      : 'Access your IT Helpdesk account',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Main Card Container
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isMobile ? 28 : 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Title
                        Text(
                          isSignUp ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Card Subtitle
                        Text(
                          isSignUp
                              ? 'Fill in your details to create your account'
                              : 'Fill in your details to access your account',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Full Name Field (Sign Up only)
                        if (isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0066FF),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 24),

                          // Role Selection Section
                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Role Selection Cards
                          Row(
                            children: [
                              // End User Role Card
                              Expanded(
                                child: _buildRoleSelectionCard(
                                  role: 'user',
                                  icon: Icons.person_outline_rounded,
                                  title: 'End User',
                                  subtitle: 'Report issues',
                                  isSelected: _selectedRole == 'user',
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = 'user';
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Engineer Role Card
                              Expanded(
                                child: _buildRoleSelectionCard(
                                  role: 'engineer',
                                  icon: Icons.engineering_outlined,
                                  title: 'Engineer',
                                  subtitle: 'Handle tickets',
                                  isSelected: _selectedRole == 'engineer',
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = 'engineer';
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@company.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: isSignUp
                                ? 'Create a password'
                                : 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF0066FF),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field (Sign Up only)
                        if (isSignUp) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0066FF),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                        ] else
                          const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF93C5FD),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isSignUp ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Divider with "OR TRY DEMO"
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR TRY DEMO',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE5E7EB),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Role Selection Cards
                        Row(
                          children: [
                            // End User Card
                            Expanded(
                              child: _buildRoleCard(
                                context: context,
                                icon: Icons.person_outline_rounded,
                                title: 'End User',
                                subtitle: 'Report issues',
                                onTap: () {
                                  // Navigate to user dashboard
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/dashboard',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Engineer Card
                            Expanded(
                              child: _buildRoleCard(
                                context: context,
                                icon: Icons.engineering_outlined,
                                title: 'Engineer',
                                subtitle: 'Handle tickets',
                                onTap: () {
                                  // Navigate to engineer dashboard
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/engineer-dashboard',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Toggle Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isSignUp
                                  ? 'Already have an account?'
                                  : 'Don\'t have an account?',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleAuthMode,
                              child: Text(
                                isSignUp ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  color: Color(0xFF0066FF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Company IT Department',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build role selection card for sign-up form
  Widget _buildRoleSelectionCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(icon, size: 36, color: const Color(0xFF0066FF)),
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066FF),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF0066FF)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // Build role selection card
  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF0066FF)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
