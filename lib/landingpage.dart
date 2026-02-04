import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LANDING PAGE - Entry Point (Fully Responsive)
// ═══════════════════════════════════════════════════════════════════════════
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine device type based on breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Navigation Bar - Responsive
          _buildTopNavigationBar(context, isMobile, isTablet, isDesktop),
          // Hero Section - Responsive
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : (isTablet ? 32 : 48),
                  vertical: isMobile ? 40 : (isTablet ? 50 : 60),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildHeroSection(
                    context,
                    isMobile,
                    isTablet,
                    isDesktop,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top Navigation Bar with responsive layout
  Widget _buildTopNavigationBar(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isTablet ? 24 : 48),
        vertical: isMobile ? 12 : (isTablet ? 16 : 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? _buildMobileNavigation(context)
          : _buildDesktopNavigation(context, isTablet),
    );
  }

  // Desktop and Tablet Navigation (horizontal layout)
  Widget _buildDesktopNavigation(BuildContext context, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Logo/Brand
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: isTablet ? 24 : 28,
              ),
            ),
            SizedBox(width: isTablet ? 10 : 14),
            Text(
              'IT Helpdesk',
              style: TextStyle(
                fontSize: isTablet ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Auth Buttons
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/auth',
                  arguments: {'mode': 'signin'},
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 20,
                  vertical: isTablet ? 10 : 12,
                ),
              ),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 8 : 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/auth',
                  arguments: {'mode': 'signup'},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 28,
                  vertical: isTablet ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Mobile Navigation (compact layout)
  Widget _buildMobileNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Logo/Brand - Smaller for mobile
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
            const SizedBox(width: 10),
            const Text(
              'IT Helpdesk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        // Compact Auth Buttons
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/auth',
                  arguments: {'mode': 'signin'},
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/auth',
                  arguments: {'mode': 'signup'},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Hero Section with responsive layout
  Widget _buildHeroSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge - Responsive
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : (isTablet ? 16 : 20),
            vertical: isMobile ? 8 : (isTablet ? 9 : 10),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                color: const Color(0xFF0066FF),
                size: isMobile ? 16 : (isTablet ? 18 : 20),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                isMobile ? 'Smart Support' : 'Smart Support for Modern Teams',
                style: TextStyle(
                  color: const Color(0xFF0066FF),
                  fontSize: isMobile ? 12 : (isTablet ? 13 : 15),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
        // Main Headline - Responsive
        Text(
          'Smart Helpdesk for',
          style: TextStyle(
            fontSize: isMobile ? 32 : (isTablet ? 48 : 64),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            height: 1.1,
            letterSpacing: isMobile ? -0.8 : (isTablet ? -1.2 : -1.5),
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Faster Tech Support',
          style: TextStyle(
            fontSize: isMobile ? 32 : (isTablet ? 48 : 64),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0066FF),
            height: 1.1,
            letterSpacing: isMobile ? -0.8 : (isTablet ? -1.2 : -1.5),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile ? 20 : (isTablet ? 24 : 32)),
        // Description - Responsive
        Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : (isTablet ? 600 : 750),
          ),
          child: Text(
            'Streamline your IT support with automatic issue categorization, intelligent quick-fix suggestions, and smart ticket escalation. Get help faster, resolve issues quicker.',
            style: TextStyle(
              fontSize: isMobile ? 16 : (isTablet ? 18 : 20),
              color: const Color(0xFF64748B),
              height: 1.6,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isMobile ? 32 : (isTablet ? 40 : 48)),
        // CTA Buttons - Responsive
        _buildCTAButtons(context, isMobile, isTablet),
      ],
    );
  }

  // CTA Buttons with responsive layout
  Widget _buildCTAButtons(BuildContext context, bool isMobile, bool isTablet) {
    if (isMobile) {
      // Stack buttons vertically on mobile
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/auth',
                arguments: {'mode': 'signup'},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/auth',
                arguments: {'mode': 'signin'},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0066FF),
              side: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign In to Your Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      );
    } else {
      // Horizontal layout for tablet and desktop
      return Wrap(
        spacing: isTablet ? 12 : 16,
        runSpacing: isTablet ? 12 : 16,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/auth',
                arguments: {'mode': 'signup'},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 36,
                vertical: isTablet ? 16 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 10),
                Icon(Icons.arrow_forward_rounded, size: isTablet ? 18 : 20),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/auth',
                arguments: {'mode': 'signin'},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0066FF),
              side: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 36,
                vertical: isTablet ? 16 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign In to Your Account',
              style: TextStyle(
                fontSize: isTablet ? 16 : 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      );
    }
  }
}
