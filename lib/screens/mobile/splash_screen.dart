import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // CRITICAL: Call the async session check
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Give the splash at least 3 seconds of "screen time"
    await Future.delayed(const Duration(seconds: 3));

    // 2. Obtain shared preferences instance
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 3. Read the 'user_roll' key
    final String? rollNo = prefs.getString('user_roll');

    if (mounted) {
      if (rollNo != null && rollNo.isNotEmpty) {
        // SUCCESS: Student is already logged in, skip Login
        Navigator.pushNamedAndRemoveUntil(context, '/student_app', (route) => false);
      } else {
        // FAIL: No session found, go to Login
        Navigator.pushNamedAndRemoveUntil(context, '/mobile_login', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.yellow.withOpacity(0.15)),
                  ),
                ),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: FadeTransition(
                    opacity: ReverseAnimation(_pulseController),
                    child: Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5)),
                    ),
                  ),
                ),
                ClipOval(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    color: Colors.white,
                    child: Image.asset('assets/images/logo.png', height: 120, width: 120, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            const Text("GPCS", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0A2E50), letterSpacing: 4.0)),
            const SizedBox(height: 8),
            Container(height: 2, width: 45, color: AppStyle.primaryTeal),
            const SizedBox(height: 15),
            const Text("HOSTEL PORTAL", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.grey, letterSpacing: 6.0)),
          ],
        ),
      ),
    );
  }
}