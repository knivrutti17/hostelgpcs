import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'styles.dart';

// REUSABLE TOP HEADER
Widget buildCommonHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    color: Colors.white,
    child: Row(
      children: [
        Image.asset(
          'assets/images/gpcslogo.png',
          height: 75,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppColors.primaryBlue, size: 40),
            );
          },
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SelectableText(
                "Government Polytechnic, Chhatrapati Sambhajinagar Hostel Portal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const Text(
                "(शासकीय तंत्रनिकेतन, छत्रपती संभाजीनगर वसतिगृह पोर्टल)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                "Online Academic Management System",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// REUSABLE NAVIGATION STRIP WITH MARQUEE
// FIXED: Wrapped Marquee in a SizedBox to prevent mobile layout crashes
Widget buildCommonNavStrip({required List<Widget> navLinks, String? marqueeText}) {
  return Container(
    height: 45,
    color: AppColors.primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Row(children: navLinks),
        if (marqueeText != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 40.0),
              // WRAPPING IN SIZEDBOX FIXES NULL CHECK ERROR ON MOBILE
              child: SizedBox(
                height: 30,
                child: Marquee(
                  text: "$marqueeText          ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  scrollAxis: Axis.horizontal,
                  blankSpace: 100.0,
                  velocity: 30.0,
                  pauseAfterRound: const Duration(seconds: 1),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// REUSABLE NAV BUTTON
Widget navLink(String label, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ),
  );
}