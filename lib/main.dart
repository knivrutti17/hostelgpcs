import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import 'package:gpcs_hostel_portal/firebase_options.dart';

// Import Style File
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

// Import Web & Staff Screens
import 'package:gpcs_hostel_portal/screens/portal_page.dart';
import 'package:gpcs_hostel_portal/screens/login_page.dart';
import 'package:gpcs_hostel_portal/screens/warden/warden_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/hod_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/Admin/admin_main.dart';

// Import Mobile Student Screens
import 'package:gpcs_hostel_portal/screens/mobile/splash_screen.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_login.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_register.dart';
import 'package:gpcs_hostel_portal/screens/mobile/complain.dart';
import 'package:gpcs_hostel_portal/screens/mobile/room_details_screen.dart';

// ATTENDANCE SYSTEM IMPORTS
import 'package:gpcs_hostel_portal/screens/admin/attendance_config_view.dart';
import 'package:gpcs_hostel_portal/screens/mobile/attendance_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Check Session Status
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // Key must match what is saved in MobileAuthService
  final String? rollNo = prefs.getString('user_roll');

  // 3. Run App with login state
  runApp(MyApp(isLoggedIn: rollNo != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GPCS Hostel Portal',
      theme: ThemeData(
        primaryColor: AppStyle.primaryTeal,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyle.primaryTeal),
        useMaterial3: true,
      ),

      // Logic: Web goes to Portal, Mobile goes to Splash
      initialRoute: kIsWeb ? '/' : '/splash',

      routes: {
        // --- WEB & STAFF ROUTES ---
        '/': (context) => const PortalPage(),
        '/login': (context) => const LoginPage(),
        '/warden': (context) => const WardenDashboard(),
        '/hod': (context) => const HODDashboard(),
        '/admin': (context) => const AdminDashboard(),

        // --- ATTENDANCE ROUTES ---
        '/attendance_setup': (context) => AttendanceConfigView(),
        '/attendance_page': (context) => const AttendancePage(),

        // --- MOBILE STUDENT ROUTES ---
        '/splash': (context) => const SplashScreen(),
        '/mobile_login': (context) => const StudentMobileLogin(),
        '/student_register': (context) => const StudentRegister(),

        // This handles the automatic login redirection
        '/student_app': (context) => const StudentDashboard(),

        // OTHER ROUTES
        '/register_complaint': (context) => const RegisterComplaint(),
        '/room_details_screen': (context) => const RoomDetailsScreen(),
      },
    );
  }
}