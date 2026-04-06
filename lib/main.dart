import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'landingpage.dart';
import 'authpage.dart';
import 'user_dashboard.dart';
import 'engineer_dashboard.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';
// Feature Added: new pages registered as named routes
import 'analytics_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB3KXAyw945WNGYTDjfgrRx6ZdvXjC-sMg",
      authDomain: "scholaproject-dcbab.firebaseapp.com",
      projectId: "scholaproject-dcbab",
      storageBucket: "scholaproject-dcbab.firebasestorage.app",
      messagingSenderId: "363202990216",
      appId: "1:363202990216:web:d13f3a5789870c5ed90f3d",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IT Helpdesk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF0066FF),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          primary: const Color(0xFF0066FF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/auth': (context) => const AuthPage(),
        '/signup': (context) => const AuthPage(),
        '/signin': (context) => const AuthPage(),
        '/dashboard': (context) => const UserDashboard(),
        '/engineer-dashboard': (context) => const EngineerDashboard(),
        '/create-ticket': (context) => const CreateTicketPage(),
        // Feature Added: routes for new pages
        '/analytics': (context) => const AnalyticsPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ticket-detail') {
          final ticketId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => TicketDetailPage(ticketId: ticketId),
          );
        }
        return null;
      },
    );
  }
}
