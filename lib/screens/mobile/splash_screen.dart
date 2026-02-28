import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart'; //

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

    // 1. Advanced Energy Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // 2. Navigation Timer (4 Seconds)
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/mobile_login');
      }
    });
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
            // STACK: Animated Rings + Your New logo.png
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse (Yellow)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow.withOpacity(0.15),
                    ),
                  ),
                ),
                // Inner Pulse (Orange)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: FadeTransition(
                    opacity: ReverseAnimation(_pulseController),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 1.5
                        ),
                      ),
                    ),
                  ),
                ),
                // STABLE LOGO FIX: Using logo.png
                ClipOval(
                  child: Container(
                    padding: const EdgeInsets.all(5), // Padding for clean edges
                    color: Colors.white, // Covers any "proper" image issues
                    child: Image.asset(
                      'assets/images/logo.png', // UPDATED PATH
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Professional Typography
            const Text(
              "GPCS",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0A2E50),
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 2, width: 45, color: AppStyle.primaryTeal),
            const SizedBox(height: 15),
            const Text(
              "HOSTEL PORTAL",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.grey,
                letterSpacing: 6.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}