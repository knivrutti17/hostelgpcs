import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
        primaryColor: AppStyle.primaryTeal,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyle.primaryTeal),
        useMaterial3: true,
      ),

      initialRoute: kIsWeb ? '/' : '/splash',

      routes: {
        // --- WEB & STAFF ROUTES ---
        '/': (context) => const PortalPage(),
        '/login': (context) => const LoginPage(),
        '/warden': (context) => const WardenDashboard(),
        '/hod': (context) => const HODDashboard(),
        '/admin': (context) => const AdminDashboard(),

        // --- ATTENDANCE ROUTES ---
        // Admin uses this to set GPS Coordinates and Time
        // NO 'const' here because it contains TextEditingControllers
        '/attendance_setup': (context) => AttendanceConfigView(),

        // Student uses this to mark daily attendance via GPS
        // 'const' is okay here as the constructor allows it
        '/attendance_page': (context) => const AttendancePage(),

        // --- MOBILE STUDENT ROUTES ---
        '/splash': (context) => const SplashScreen(),
        '/mobile_login': (context) => const StudentMobileLogin(),
        '/student_register': (context) => const StudentRegister(),
        '/student_app': (context) => const StudentDashboard(),

        // OTHER ROUTES
        '/register_complaint': (context) => const RegisterComplaint(),
        '/room_details_screen': (context) => const RoomDetailsScreen(),
      },
    );
  }
}