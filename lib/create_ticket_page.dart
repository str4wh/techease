import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

// ═══════════════════════════════════════════════════════════════════════════
// CREATE TICKET PAGE - Multi-Step Ticket Creation Form
// ═══════════════════════════════════════════════════════════════════════════
class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Form data
  int _currentStep = 0;
  String _title = '';
  String _category = '';
  String _priority = 'Medium';
  String _description = '';
  bool _isSubmitting = false;

  // AI-generated response data from n8n
  Map<String, dynamic>? _aiResponse;
  String? _aiSolutions;
  String? _aiNextSteps;
  String? _aiEstimatedTime;

  final List<String> _categories = [
    'Network Issues',
    'Software Problems',
    'Hardware Issues',
    'Account & Access',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  String get firstName {
    final fullName = user?.displayName ?? 'User';
    return fullName.split(' ').first;
  }

  String get fullName => user?.displayName ?? 'User';

  // Submit form data to webhook and get AI response
  Future<bool> _submitToWebhook() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final payload = {
        'title': _title,
        'category': _category,
        'priority': _priority,
        'description': _description,
        'createdBy': user?.displayName ?? 'Unknown User',
        'createdByEmail': user?.email ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final webhookUrl =
          'http://localhost:5678/webhook-test/771b5897-fb4d-45e6-80dc-ea980d77fdc9';

      print('=== WEBHOOK DEBUG START ===');
      print('Request URL: $webhookUrl');
      print('Request Body: ${json.encode(payload)}');

      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      print('=== RAW RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body Type: ${response.body.runtimeType}');
      print('Full Response: ${response.body}');
      print('===================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        print('=== PARSED DATA DEBUG ===');
        print('Parsed data type: ${responseData.runtimeType}');
        if (responseData is Map) {
          print('Data keys: ${responseData.keys}');
          print(
            'Analysis field type: ${responseData['analysis']?.runtimeType}',
          );
          print('Analysis content: ${responseData['analysis']}');
          print(
            'Solutions field type: ${responseData['solutions']?.runtimeType}',
          );
          print('Solutions content: ${responseData['solutions']}');
          print('NextSteps field: ${responseData['nextSteps']}');
          print('EstimatedTime field: ${responseData['estimatedTime']}');
          print('RawOutput field: ${responseData['rawOutput']}');
        }
        print('========================');

        // Store the full AI response
        _aiResponse = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : {};

        // Initialize variables
        String solutions = '';
        String nextSteps = '';
        String estimatedTime = '';

        // Handle if response is a List (array)
        dynamic data = responseData;
        if (responseData is List && responseData.isNotEmpty) {
          print('Response is a List, taking first item');
          data = responseData[0];
        }

        if (data is Map) {
          // ============================================================
          // STEP 1: Try to extract from 'solutions' array first
          // ============================================================
          if (data['solutions'] != null && data['solutions'] is List) {
            print('Processing solutions array...');
            List solutionsList = data['solutions'] as List;
            if (solutionsList.isNotEmpty) {
              solutions = solutionsList
                  .map((solution) {
                    if (solution is Map) {
                      String step = solution['step']?.toString() ?? '';
                      String title = solution['title']?.toString() ?? '';
                      String desc = solution['description']?.toString() ?? '';

                      if (title.isNotEmpty && desc.isNotEmpty) {
                        return '${step.isNotEmpty ? "$step. " : ""}$title\n  $desc';
                      } else if (title.isNotEmpty) {
                        return '• $title';
                      }
                    }
                    return '• ${solution.toString()}';
                  })
                  .join('\n\n');
              print('✓ Extracted solutions from solutions array');
            }
          }

          // ============================================================
          // STEP 2: Try 'rawOutput' field (unprocessed AI response)
          // ============================================================
          if (solutions.isEmpty && data['rawOutput'] != null) {
            var rawOutput = data['rawOutput'].toString();
            if (rawOutput.isNotEmpty && rawOutput != 'null') {
              solutions = rawOutput;
              print('✓ Using rawOutput field');
            }
          }

          // ============================================================
          // STEP 3: Parse the 'analysis' field (JSON inside JSON)
          // ============================================================
          if (solutions.isEmpty && data['analysis'] != null) {
            print('Attempting to parse analysis field...');
            try {
              var analysisData = data['analysis'];

              // If analysis is a JSON string, parse it
              if (analysisData is String) {
                print('Analysis is a string, attempting JSON decode...');
                try {
                  var parsedAnalysis = json.decode(analysisData);
                  print('Successfully parsed analysis string');
                  print(
                    'Parsed analysis keys: ${parsedAnalysis is Map ? parsedAnalysis.keys : "not a map"}',
                  );

                  // Check for nested 'json' wrapper
                  if (parsedAnalysis is Map && parsedAnalysis['json'] != null) {
                    print('Found nested json wrapper');
                    var innerData = parsedAnalysis['json'];

                    // Extract analysis text
                    if (innerData['analysis'] != null) {
                      solutions = innerData['analysis'].toString();
                      print('✓ Extracted from json.analysis');
                    }

                    // Extract solutions array if it exists
                    if (innerData['solutions'] != null &&
                        innerData['solutions'] is List) {
                      List innerSolutions = innerData['solutions'];
                      String formattedSolutions = innerSolutions
                          .map((s) {
                            if (s is Map) {
                              return '${s['step']}. ${s['title']}: ${s['description']}';
                            }
                            return s.toString();
                          })
                          .join('\n\n');

                      if (formattedSolutions.isNotEmpty) {
                        solutions = formattedSolutions;
                        print('✓ Extracted from json.solutions array');
                      }
                    }
                  } else if (parsedAnalysis is Map) {
                    // No 'json' wrapper, use parsed data directly
                    if (parsedAnalysis['analysis'] != null) {
                      solutions = parsedAnalysis['analysis'].toString();
                      print('✓ Extracted from direct analysis field');
                    } else {
                      solutions = parsedAnalysis.toString();
                      print('✓ Using entire parsed analysis object');
                    }
                  }
                } catch (e) {
                  print('Analysis string is not valid JSON, using as-is: $e');
                  solutions = analysisData;
                }
              } else if (analysisData is Map) {
                // Analysis is already an object
                solutions =
                    analysisData['solutions']?.toString() ??
                    analysisData['analysis']?.toString() ??
                    analysisData.toString();
                print('✓ Extracted from analysis object');
              } else if (analysisData is List) {
                solutions = (analysisData as List)
                    .map((s) => s.toString())
                    .join('\n\n');
                print('✓ Extracted from analysis list');
              } else {
                solutions = analysisData.toString();
                print('✓ Using analysis as string');
              }
            } catch (e) {
              print('❌ Error parsing analysis field: $e');
              // Fallback to raw string
              if (data['analysis'] != null) {
                solutions = data['analysis'].toString();
              }
            }
          }

          // ============================================================
          // STEP 4: Extract Next Steps
          // ============================================================
          if (data['nextSteps'] != null) {
            if (data['nextSteps'] is List) {
              nextSteps = (data['nextSteps'] as List)
                  .map((step) => '• ${step.toString()}')
                  .join('\n');
            } else if (data['nextSteps'] is String) {
              nextSteps = data['nextSteps'];
            } else {
              nextSteps = data['nextSteps'].toString();
            }
            print('✓ Found nextSteps: $nextSteps');
          } else if (data['next_steps'] != null) {
            if (data['next_steps'] is List) {
              nextSteps = (data['next_steps'] as List)
                  .map((step) => '• ${step.toString()}')
                  .join('\n');
            } else {
              nextSteps = data['next_steps'].toString();
            }
            print('✓ Found next_steps: $nextSteps');
          }

          // ============================================================
          // STEP 5: Extract Estimated Time
          // ============================================================
          if (data['estimatedTime'] != null &&
              data['estimatedTime'].toString() != 'null' &&
              data['estimatedTime'].toString().isNotEmpty) {
            estimatedTime = data['estimatedTime'].toString();
            print('✓ Found estimatedTime: $estimatedTime');
          } else if (data['estimated_time'] != null &&
              data['estimated_time'].toString() != 'null' &&
              data['estimated_time'].toString().isNotEmpty) {
            estimatedTime = data['estimated_time'].toString();
            print('✓ Found estimated_time: $estimatedTime');
          }
        }

        // Set the values (with fallbacks)
        _aiSolutions = solutions.isNotEmpty
            ? solutions
            : 'Unable to retrieve AI solutions at this time. Our IT team will analyze your issue manually.';

        _aiNextSteps = nextSteps.isNotEmpty
            ? nextSteps
            : 'Please proceed to submit your ticket for manual review by our support team.';

        _aiEstimatedTime = estimatedTime.isNotEmpty
            ? estimatedTime
            : 'Our team will respond within 24 hours';

        print('=== FINAL PARSED RESULTS ===');
        print('Solutions: $_aiSolutions');
        print('Next Steps: $_aiNextSteps');
        print('Estimated Time: $_aiEstimatedTime');
        print('=== WEBHOOK DEBUG END ===');

        return true;
      } else {
        print('Webhook returned non-200 status: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Webhook timeout error: $e');
    } on SocketException catch (e) {
      print('Network/Socket error: $e');
    } catch (e, stackTrace) {
      print('Webhook error: $e');
      print('Stack trace: $stackTrace');
    }

    // Set fallback values if webhook fails
    _aiSolutions =
        'Unable to retrieve AI solutions at this time. Our IT team will analyze your issue manually.';
    _aiNextSteps =
        'Please proceed to submit your ticket for manual review by our support team.';
    _aiEstimatedTime = 'Our team will respond within 24 hours';

    return false;
  }

  // Show loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Color(0xFF0066FF),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'IT helpdesk is looking for a solution to your problem',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Handle Continue button press
  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show loading dialog
      _showLoadingDialog(context);

      // 1. Create Firestore document
      await FirebaseFirestore.instance.collection('ticket_analysis').add({
        'title': _title,
        'category': _category,
        'priority': _priority,
        'description': _description,
        'status': 'pending',
        'solutions': [],
        'createdBy': user?.displayName ?? 'Unknown User',
        'createdByEmail': user?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Submit to webhook and get AI response
      final success = await _submitToWebhook();

      // Close loading dialog if mounted
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to Step 2 to show AI solutions
        setState(() {
          _currentStep = 1; // Always show AI solutions in Step 2
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopNavigationBar(context, isMobile, isTablet, isDesktop),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Progress Stepper
                        _buildProgressStepper(isMobile),
                        const SizedBox(height: 40),
                        // Step Content
                        _buildStepContent(isMobile, isTablet),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Drawer (same as dashboard)
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0066FF)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            accountName: Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF0066FF),
            ),
            title: const Text('New Ticket'),
            selected: true,
            selectedColor: const Color(0xFF0066FF),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number_outlined),
            title: const Text('My Tickets'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFEF4444)),
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
    );
  }

  // Top Navigation Bar
  Widget _buildTopNavigationBar(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              color: const Color(0xFF1A1A1A),
            ),
            const SizedBox(width: 8),
          ],
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'IT Helpdesk',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(width: 48),
            _buildNavItem(
              Icons.dashboard_outlined,
              'Dashboard',
              false,
              isTablet,
              '/dashboard',
            ),
            const SizedBox(width: 24),
            _buildNavItem(
              Icons.add_circle_outline,
              'New Ticket',
              true,
              isTablet,
              '/create-ticket',
            ),
            const SizedBox(width: 24),
            _buildNavItem(
              Icons.confirmation_number_outlined,
              'My Tickets',
              false,
              isTablet,
              null,
            ),
          ],
          const Spacer(),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                color: const Color(0xFF64748B),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // User Profile
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF0066FF),
                    child: Text(
                      firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 8),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
                onTap: () {},
              ),
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
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    bool isTablet,
    String? route,
  ) {
    final showFullText = !isTablet;

    return InkWell(
      onTap: route != null
          ? () => Navigator.pushReplacementNamed(context, route)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF0066FF)
                  : const Color(0xFF64748B),
            ),
            if (showFullText) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF0066FF)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Progress Stepper
  Widget _buildProgressStepper(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 600,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1
          _buildStepIndicator(
            stepNumber: 1,
            label: 'Describe Your Issue',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            isMobile: isMobile,
          ),
          // Line
          _buildConnectingLine(_currentStep > 0),
          // Step 2
          _buildStepIndicator(
            stepNumber: 2,
            label: 'Quick Fixes',
            isActive: _currentStep == 1,
            isCompleted: _currentStep > 1,
            isMobile: isMobile,
          ),
          // Line
          _buildConnectingLine(_currentStep > 1),
          // Step 3
          _buildStepIndicator(
            stepNumber: 3,
            label: 'Review & Submit',
            isActive: _currentStep == 2,
            isCompleted: false,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required bool isMobile,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isActive
                  ? const Color(0xFF0066FF)
                  : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      stepNumber.toString(),
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isMobile)
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildConnectingLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
      ),
    );
  }

  // Step Content
  Widget _buildStepContent(bool isMobile, bool isTablet) {
    switch (_currentStep) {
      case 0:
        return _buildStep1DescribeIssue(isMobile);
      case 1:
        return _buildStep2QuickFixes(isMobile);
      case 2:
        return _buildStep3ReviewSubmit(isMobile, isTablet);
      default:
        return Container();
    }
  }

  // Step 1: Describe Your Issue
  Widget _buildStep1DescribeIssue(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Describe Your Issue',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide details about the problem you\'re experiencing',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),

            // Issue Title
            _buildLabel('Issue Title', true),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Brief description of the problem',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an issue title';
                }
                return null;
              },
              onSaved: (value) => _title = value ?? '',
            ),
            const SizedBox(height: 24),

            // Category
            _buildLabel('Category', true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
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
              hint: const Text('Select a category'),
              value: _category.isEmpty ? null : _category,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
              onChanged: (String? newValue) {
                setState(() {
                  _category = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 24),

            // Priority
            _buildLabel('Priority', false),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
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
              value: _priority,
              items: _priorities.map((String priority) {
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    children: [
                      Text(priority),
                      if (priority == _priority) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF0066FF),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _priority = newValue ?? 'Medium';
                });
              },
            ),
            const SizedBox(height: 24),

            // Detailed Description
            _buildLabel('Detailed Description', true),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'Explain the issue in detail. Include any error messages, what you were doing when it occurred, etc.',
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a detailed description';
                }
                return null;
              },
              onSaved: (value) => _description = value ?? '',
            ),
            const SizedBox(height: 32),

            // Continue Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _handleContinue,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: AI-Generated Solutions Display
  Widget _buildStep2QuickFixes(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF0066FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis Complete',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here\'s what our AI helpdesk found',
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recommended Solutions Section - Always show
          _buildAISectionCard(
            icon: Icons.lightbulb_outline,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFFFF4E6),
            title: 'Recommended Solutions',
            content:
                _aiSolutions ??
                'Unable to retrieve AI solutions at this time. Our IT team will analyze your issue manually.',
          ),
          const SizedBox(height: 20),

          // Next Steps Section - Always show
          _buildAISectionCard(
            icon: Icons.format_list_numbered,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: const Color(0xFFF3E8FF),
            title: 'Next Steps',
            content:
                _aiNextSteps ??
                'Please proceed to submit your ticket for manual review by our support team.',
          ),
          const SizedBox(height: 20),

          // Estimated Time Section - Always show
          _buildAISectionCard(
            icon: Icons.access_time,
            iconColor: const Color(0xFF06B6D4),
            iconBgColor: const Color(0xFFE0F2FE),
            title: 'Estimated Resolution Time',
            content:
                _aiEstimatedTime ?? 'Our team will respond within 24 hours',
          ),
          const SizedBox(height: 20),

          const SizedBox(height: 12),

          // Divider
          const Divider(height: 40),

          // Question
          const Center(
            child: Text(
              'Did this information help resolve your issue?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (isMobile) ...[
            // Mobile: Stack buttons vertically
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Show success message and go back to dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Great! Your issue has been resolved.'),
                      backgroundColor: Color(0xFF10B981),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Issue Resolved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 2; // Navigate to Step 3
                  });
                },
                icon: const Icon(Icons.support_agent, size: 20),
                label: const Text('Still Need Help'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0; // Go back to Step 1
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Desktop/Tablet: Side by side
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Show success message and go back to dashboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Great! Your issue has been resolved.'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Issue Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep = 2; // Navigate to Step 3
                      });
                    },
                    icon: const Icon(Icons.support_agent, size: 20),
                    label: const Text('Still Need Help'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Back button centered
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0; // Go back to Step 1
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build AI section cards
  Widget _buildAISectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Review & Submit
  Widget _buildStep3ReviewSubmit(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
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
          // Header
          Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your ticket details before submitting',
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          // Review Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewField('Title', _title),
                const SizedBox(height: 20),
                _buildReviewField('Category', _category),
                const SizedBox(height: 20),
                _buildReviewField('Priority', _priority),
                const SizedBox(height: 20),
                _buildReviewField('Description', _description),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              if (!isMobile)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = _category == 'Software Problems' ? 1 : 0;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (!isMobile) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  icon: _isSubmitting
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
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Ticket',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = _category == 'Software Problems' ? 1 : 0;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // Submit Ticket to Firestore
  Future<void> _submitTicket() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final ticketRef = await FirebaseFirestore.instance
          .collection('tickets')
          .add({
            'title': _title,
            'category': _category,
            'priority': _priority,
            'description': _description,
            'status': 'Open',
            'createdBy': user?.uid,
            'createdByName': user?.displayName ?? 'Unknown User',
            'createdByEmail': user?.email ?? '',
            // AI-generated data from Step 2
            'aiSolutions': _aiSolutions ?? '',
            'aiNextSteps': _aiNextSteps ?? '',
            'aiEstimatedTime': _aiEstimatedTime ?? '',
            'assignedTo': null,
            'assignedToName': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'timeline': [
              {
                'action': 'Ticket created',
                'by': user?.displayName ?? 'Unknown User',
                'timestamp': Timestamp.fromDate(DateTime.now()),
              },
            ],
          });

      if (mounted) {
        // Navigate to ticket detail page
        Navigator.pushReplacementNamed(
          context,
          '/ticket-detail',
          arguments: ticketRef.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ticket: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
