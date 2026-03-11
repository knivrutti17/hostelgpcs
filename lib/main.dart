import 'dart:async';
import 'dart:io'; // Required for Platform check
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gpcs_hostel_portal/firebase_options.dart';

// Import screens
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/screens/mobile/splash_screen.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_login.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_register.dart';
import 'package:gpcs_hostel_portal/screens/mobile/complain.dart';
import 'package:gpcs_hostel_portal/screens/mobile/room_details_screen.dart';
import 'package:gpcs_hostel_portal/screens/portal_page.dart';
import 'package:gpcs_hostel_portal/screens/login_page.dart';
import 'package:gpcs_hostel_portal/screens/warden/warden_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/hod_dashboard.dart';
import 'package:gpcs_hostel_portal/screens/Admin/admin_main.dart';
import 'package:gpcs_hostel_portal/screens/admin/attendance_config_view.dart';
import 'package:gpcs_hostel_portal/screens/mobile/attendance_page.dart';

// --- NEW FUNCTION: REQUEST PERMISSION DIALOG (Android 13+) ---
Future<void> requestNotificationPermissions() async {
  if (!kIsWeb && Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin localNotify = FlutterLocalNotificationsPlugin();
    // This triggers the standard Android "Allow notifications?" pop-up
    await localNotify
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}

// --- STEP 1: BACKGROUND SERVICE CONFIGURATION ---
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_sync',
    'Hostel Chat Sync',
    description: 'Notifications for hostel messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin localNotify = FlutterLocalNotificationsPlugin();

  await localNotify.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await localNotify
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'chat_sync',
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'GPCS Hostel Hub',
      initialNotificationContent: 'Syncing messages...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FlutterLocalNotificationsPlugin localNotify = FlutterLocalNotificationsPlugin();

  await localNotify.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  FirebaseFirestore.instance
      .collection('chats')
      .doc('hostel_public')
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) async {

    if (snapshot.docs.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Refresh the disk data

      var msg = snapshot.docs.first;
      String msgId = msg.id;
      String? myRoll = prefs.getString('user_roll');
      String senderId = msg['senderId']?.toString() ?? "";
      String? lastNotifiedId = prefs.getString('last_msg_id');

      // LOGIC: Show notification only if it's NEW and NOT from me
      if (msgId != lastNotifiedId && myRoll != null && senderId != myRoll) {
        await prefs.setString('last_msg_id', msgId);

        _showLocalNotification(
            localNotify,
            msg['senderName'] ?? "Hostel Message",
            msg['messageText'] ?? ""
        );
      }
    }
  });
}

void _showLocalNotification(FlutterLocalNotificationsPlugin plugin, String title, String body) {
  plugin.show(
    DateTime.now().millisecond,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_sync',
        'Chat Alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    ),
  );
}

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? rollNo = prefs.getString('user_roll');

  runApp(MyApp(isLoggedIn: rollNo != null));

  if (!kIsWeb) {
    // 1. Trigger the "Allow Notifications" Pop-up immediately
    await requestNotificationPermissions();

    // 2. Start Service after UI settle
    Timer(const Duration(seconds: 2), () {
      initializeService();
    });
  }
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
      initialRoute: isLoggedIn ? '/student_app' : (kIsWeb ? '/' : '/splash'),
      routes: {
        '/': (context) => const PortalPage(),
        '/login': (context) => const LoginPage(),
        '/warden': (context) => const WardenDashboard(),
        '/hod': (context) => const HODDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/attendance_setup': (context) => AttendanceConfigView(),
        '/attendance_page': (context) => const AttendancePage(),
        '/splash': (context) => const SplashScreen(),
        '/mobile_login': (context) => const StudentMobileLogin(),
        '/student_register': (context) => const StudentRegister(),
        '/student_app': (context) => const StudentDashboard(),
        '/register_complaint': (context) => const RegisterComplaint(),
        '/room_details_screen': (context) => const RoomDetailsScreen(),
      },
    );
  }
}