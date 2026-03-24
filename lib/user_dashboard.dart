import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// USER DASHBOARD - Main Dashboard for End Users
// ═══════════════════════════════════════════════════════════════════════════
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Get user's first name from display name
  String get firstName {
    final fullName = user?.displayName ?? 'User';
    return fullName.split(' ').first;
  }

  String get fullName => user?.displayName ?? 'User';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    // Responsive padding
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final verticalSpacing = isMobile ? 20.0 : (isTablet ? 28.0 : 32.0);

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
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(context, isMobile, isTablet),
                        SizedBox(height: verticalSpacing),
                        // Statistics Cards
                        _buildStatisticsCards(isMobile, isTablet, isDesktop),
                        SizedBox(height: verticalSpacing),
                        // Recent Tickets Section
                        _buildRecentTicketsSection(isMobile, isTablet),
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

  // Mobile Drawer
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
            leading: const Icon(
              Icons.dashboard_outlined,
              color: Color(0xFF0066FF),
            ),
            title: const Text('Dashboard'),
            selected: true,
            selectedColor: const Color(0xFF0066FF),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New Ticket'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/create-ticket');
            },
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number_outlined),
            title: const Text('My Tickets'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
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
          // Hamburger menu on mobile
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              color: const Color(0xFF1A1A1A),
            ),
            const SizedBox(width: 8),
          ],
          // Logo and Title
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
            // Navigation Items
            _buildNavItem(
              Icons.dashboard_outlined,
              'Dashboard',
              true,
              isTablet,
            ),
            const SizedBox(width: 24),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/create-ticket'),
              child: _buildNavItem(
                Icons.add_circle_outline,
                'New Ticket',
                false,
                isTablet,
              ),
            ),
            const SizedBox(width: 24),
            _buildNavItem(
              Icons.confirmation_number_outlined,
              'My Tickets',
              false,
              isTablet,
            ),
          ],
          const Spacer(),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Show notifications dropdown
                  _showNotificationsMenu(context);
                },
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
          // User Profile Button
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

  // Navigation Item
  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    bool isTablet,
  ) {
    // On tablet, show icon only or condensed text
    final showFullText = !isTablet;

    return Container(
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
            color: isActive ? const Color(0xFF0066FF) : const Color(0xFF64748B),
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
    );
  }

  // Welcome Section
  Widget _buildWelcomeSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    // Responsive font sizes
    final headingSize = isMobile ? 24.0 : (isTablet ? 28.0 : 32.0);
    final subtitleSize = isMobile ? 14.0 : 16.0;

    if (isMobile) {
      // Stack vertically on mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $firstName',
            style: TextStyle(
              fontSize: headingSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s an overview of your support tickets',
            style: TextStyle(
              fontSize: subtitleSize,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-ticket');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Row layout for tablet and desktop
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName',
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s an overview of your support tickets',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/create-ticket');
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Ticket'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // Statistics Cards
  Widget _buildStatisticsCards(bool isMobile, bool isTablet, bool isDesktop) {
    final cardPadding = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final cardSpacing = isMobile ? 16.0 : (isTablet ? 18.0 : 24.0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('createdBy', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCards(
            isMobile,
            isTablet,
            isDesktop,
            cardPadding,
            cardSpacing,
          );
        }

        // Error state
        if (snapshot.hasError) {
          return _buildErrorCards(
            isMobile,
            isTablet,
            isDesktop,
            cardPadding,
            cardSpacing,
          );
        }

        // Calculate statistics
        int openCount = 0;
        int pendingCount = 0;
        int resolvedThisMonth = 0;

        if (snapshot.hasData) {
          final tickets = snapshot.data!.docs;
          final now = DateTime.now();

          for (var doc in tickets) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String?;

            if (status == 'Open') {
              openCount++;
            } else if (status == 'In Progress') {
              pendingCount++;
            } else if (status == 'Resolved') {
              // Check if resolved this month
              final updatedAt = data['updatedAt'] as Timestamp?;
              if (updatedAt != null) {
                final date = updatedAt.toDate();
                if (date.year == now.year && date.month == now.month) {
                  resolvedThisMonth++;
                }
              }
            }
          }
        }

        // Build cards with real data
        if (isMobile) {
          // Stack vertically on mobile
          return Column(
            children: [
              _buildStatCard(
                Icons.confirmation_number_outlined,
                openCount.toString(),
                'Open Tickets',
                const Color(0xFFE3F2FF),
                const Color(0xFF0066FF),
                cardPadding,
                isMobile,
              ),
              SizedBox(height: cardSpacing),
              _buildStatCard(
                Icons.warning_amber_outlined,
                pendingCount.toString(),
                'Pending Response',
                const Color(0xFFFFF4E6),
                const Color(0xFFF59E0B),
                cardPadding,
                isMobile,
              ),
              SizedBox(height: cardSpacing),
              _buildStatCard(
                Icons.check_circle_outline,
                resolvedThisMonth.toString(),
                'Resolved This Month',
                const Color(0xFFE8F5E9),
                const Color(0xFF10B981),
                cardPadding,
                isMobile,
              ),
            ],
          );
        } else if (isTablet) {
          // 2 cards per row on tablet using Wrap
          return LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - cardSpacing) / 2;
              return Wrap(
                spacing: cardSpacing,
                runSpacing: cardSpacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      Icons.confirmation_number_outlined,
                      openCount.toString(),
                      'Open Tickets',
                      const Color(0xFFE3F2FF),
                      const Color(0xFF0066FF),
                      cardPadding,
                      isMobile,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      Icons.warning_amber_outlined,
                      pendingCount.toString(),
                      'Pending Response',
                      const Color(0xFFFFF4E6),
                      const Color(0xFFF59E0B),
                      cardPadding,
                      isMobile,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      Icons.check_circle_outline,
                      resolvedThisMonth.toString(),
                      'Resolved This Month',
                      const Color(0xFFE8F5E9),
                      const Color(0xFF10B981),
                      cardPadding,
                      isMobile,
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // Row layout for desktop
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.confirmation_number_outlined,
                  openCount.toString(),
                  'Open Tickets',
                  const Color(0xFFE3F2FF),
                  const Color(0xFF0066FF),
                  cardPadding,
                  isMobile,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  Icons.warning_amber_outlined,
                  pendingCount.toString(),
                  'Pending Response',
                  const Color(0xFFFFF4E6),
                  const Color(0xFFF59E0B),
                  cardPadding,
                  isMobile,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  Icons.check_circle_outline,
                  resolvedThisMonth.toString(),
                  'Resolved This Month',
                  const Color(0xFFE8F5E9),
                  const Color(0xFF10B981),
                  cardPadding,
                  isMobile,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // Loading state cards with shimmer effect
  Widget _buildLoadingCards(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double cardPadding,
    double cardSpacing,
  ) {
    final loadingCard = Container(
      padding: EdgeInsets.all(cardPadding),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          loadingCard,
          SizedBox(height: cardSpacing),
          loadingCard,
          SizedBox(height: cardSpacing),
          loadingCard,
        ],
      );
    } else if (isTablet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - cardSpacing) / 2;
          return Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            children: [
              SizedBox(width: cardWidth, child: loadingCard),
              SizedBox(width: cardWidth, child: loadingCard),
              SizedBox(width: cardWidth, child: loadingCard),
            ],
          );
        },
      );
    } else {
      return Row(
        children: [
          Expanded(child: loadingCard),
          SizedBox(width: cardSpacing),
          Expanded(child: loadingCard),
          SizedBox(width: cardSpacing),
          Expanded(child: loadingCard),
        ],
      );
    }
  }

  // Error state cards
  Widget _buildErrorCards(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double cardPadding,
    double cardSpacing,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildStatCard(
            Icons.confirmation_number_outlined,
            '-',
            'Open Tickets',
            const Color(0xFFE3F2FF),
            const Color(0xFF0066FF),
            cardPadding,
            isMobile,
          ),
          SizedBox(height: cardSpacing),
          _buildStatCard(
            Icons.warning_amber_outlined,
            '-',
            'Pending Response',
            const Color(0xFFFFF4E6),
            const Color(0xFFF59E0B),
            cardPadding,
            isMobile,
          ),
          SizedBox(height: cardSpacing),
          _buildStatCard(
            Icons.check_circle_outline,
            '-',
            'Resolved This Month',
            const Color(0xFFE8F5E9),
            const Color(0xFF10B981),
            cardPadding,
            isMobile,
          ),
        ],
      );
    } else if (isTablet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - cardSpacing) / 2;
          return Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildStatCard(
                  Icons.confirmation_number_outlined,
                  '-',
                  'Open Tickets',
                  const Color(0xFFE3F2FF),
                  const Color(0xFF0066FF),
                  cardPadding,
                  isMobile,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildStatCard(
                  Icons.warning_amber_outlined,
                  '-',
                  'Pending Response',
                  const Color(0xFFFFF4E6),
                  const Color(0xFFF59E0B),
                  cardPadding,
                  isMobile,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildStatCard(
                  Icons.check_circle_outline,
                  '-',
                  'Resolved This Month',
                  const Color(0xFFE8F5E9),
                  const Color(0xFF10B981),
                  cardPadding,
                  isMobile,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.confirmation_number_outlined,
              '-',
              'Open Tickets',
              const Color(0xFFE3F2FF),
              const Color(0xFF0066FF),
              cardPadding,
              isMobile,
            ),
          ),
          SizedBox(width: cardSpacing),
          Expanded(
            child: _buildStatCard(
              Icons.warning_amber_outlined,
              '-',
              'Pending Response',
              const Color(0xFFFFF4E6),
              const Color(0xFFF59E0B),
              cardPadding,
              isMobile,
            ),
          ),
          SizedBox(width: cardSpacing),
          Expanded(
            child: _buildStatCard(
              Icons.check_circle_outline,
              '-',
              'Resolved This Month',
              const Color(0xFFE8F5E9),
              const Color(0xFF10B981),
              cardPadding,
              isMobile,
            ),
          ),
        ],
      );
    }
  }

  // Stat Card Widget
  Widget _buildStatCard(
    IconData icon,
    String number,
    String label,
    Color bgColor,
    Color iconColor,
    double padding,
    bool isMobile,
  ) {
    // Responsive font sizes
    final statNumberSize = isMobile ? 28.0 : 32.0;
    final iconSize = isMobile ? 22.0 : 24.0;
    final iconPadding = isMobile ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(padding),
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
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: TextStyle(
              fontSize: statNumberSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Recent Tickets Section
  Widget _buildRecentTicketsSection(bool isMobile, bool isTablet) {
    // Responsive sizing
    final headerFontSize = isMobile ? 18.0 : 20.0;
    final emptyStateIconSize = isMobile ? 48.0 : (isTablet ? 56.0 : 64.0);
    final emptyStatePadding = isMobile ? 32.0 : 48.0;
    final noTicketsSize = isMobile ? 16.0 : 18.0;
    final descriptionSize = isMobile ? 12.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Tickets',
              style: TextStyle(
                fontSize: headerFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Tickets Container with StreamBuilder
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tickets')
              .where('createdBy', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: EdgeInsets.all(emptyStatePadding),
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
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0066FF)),
                ),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(emptyStatePadding),
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
                child: Center(
                  child: Text(
                    'Error loading tickets',
                    style: TextStyle(
                      fontSize: noTicketsSize,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }

            // Empty state
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: EdgeInsets.all(emptyStatePadding),
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          size: emptyStateIconSize,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No tickets yet',
                        style: TextStyle(
                          fontSize: noTicketsSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first ticket to get started',
                        style: TextStyle(
                          fontSize: descriptionSize,
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Display tickets
            final tickets = snapshot.data!.docs;

            // Sort tickets by createdAt in Dart (descending)
            tickets.sort((a, b) {
              final aTime =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            // Limit to 5 most recent
            final displayTickets = tickets.take(5).toList();

            return Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayTickets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = displayTickets[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'Untitled';
                  final status = data['status'] as String? ?? 'Open';
                  final category = data['category'] as String? ?? 'General';
                  final createdAt = data['createdAt'] as Timestamp?;

                  // Format date
                  String formattedDate = 'Just now';
                  if (createdAt != null) {
                    final date = createdAt.toDate();
                    formattedDate = DateFormat('MMM d, y').format(date);
                  }

                  // Status badge colors
                  Color statusColor;
                  Color statusBgColor;
                  switch (status) {
                    case 'Open':
                      statusColor = const Color(0xFF0066FF);
                      statusBgColor = const Color(0xFFE3F2FF);
                      break;
                    case 'In Progress':
                      statusColor = const Color(0xFFF59E0B);
                      statusBgColor = const Color(0xFFFFF4E6);
                      break;
                    case 'Resolved':
                      statusColor = const Color(0xFF10B981);
                      statusBgColor = const Color(0xFFE8F5E9);
                      break;
                    default:
                      statusColor = const Color(0xFF64748B);
                      statusBgColor = const Color(0xFFF8F9FA);
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/ticket-detail',
                        arguments: doc.id,
                      );
                    },
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Category
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          // Date
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Show Notifications Menu
  void _showNotificationsMenu(BuildContext context) {
    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 300,
        60,
        20,
        0,
      ),
      items: <PopupMenuEntry<dynamic>>[
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: Color(0xFF0066FF)),
            title: Text('Ticket #1234 updated'),
            subtitle: Text('2 hours ago'),
          ),
          onTap: () {},
        ),
        PopupMenuItem(
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            title: Text('Ticket resolved'),
            subtitle: Text('5 hours ago'),
          ),
          onTap: () {},
        ),
      ],
    );
  }
}
