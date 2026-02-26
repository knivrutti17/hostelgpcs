import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gpcs_hostel_portal/firebase_options.dart';

// Import Your New Style File
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

// Import All Screens Based on Your Folder Structure
import 'package:gpcs_hostel_portal/screens/portal_page.dart';
import 'package:gpcs_hostel_portal/screens/login_page.dart';
import 'package:gpcs_hostel_portal/screens/warden/warden_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/hod_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/Admin/admin_main.dart';

// Mobile Specific Imports
import 'package:gpcs_hostel_portal/screens/mobile/student_login.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GPCS Hostel Portal',
      theme: ThemeData(
        // FIXED: Using central AppStyle for the global theme
        primaryColor: AppStyle.primaryTeal,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyle.primaryTeal),
        useMaterial3: true,
      ),
      // Mobile starts at /mobile_login, Web starts at /
      initialRoute: kIsWeb ? '/' : '/mobile_login',

      routes: {
        // --- WEB & STAFF ROUTES ---
        '/': (context) => const PortalPage(),
        '/login': (context) => const LoginPage(),
        '/warden': (context) => const WardenDashboard(),
        '/hod': (context) => const HODDashboard(),
        '/admin': (context) => const AdminDashboard(),

        // --- MOBILE STUDENT ROUTES ---
        '/mobile_login': (context) => const StudentMobileLogin(),
        '/student_register': (context) => const StudentRegister(),
        '/student_app': (context) => const StudentDashboard(),
      },
    );
  }
}