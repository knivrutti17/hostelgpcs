import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED FOR SESSION

class StudentMobileLogin extends StatefulWidget {
  const StudentMobileLogin({super.key});

  @override
  State<StudentMobileLogin> createState() => _StudentMobileLoginState();
}

class _StudentMobileLoginState extends State<StudentMobileLogin> {
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  final MobileAuthService _authService = MobileAuthService();
  bool _isLoading = false;

  // --- SAVE FCM TOKEN TO CLOUD ---
  Future<void> saveUserToken(String rollNo) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(rollNo)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("FCM Token updated for: $rollNo");
      }
    } catch (e) {
      debugPrint("Error saving notification token: $e");
    }
  }

  // --- HANDLE LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    final String rollNo = _rollController.text.trim();
    final String password = _passwordController.text.trim();

    if (rollNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter both Roll Number and Password"))
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Authenticate with Firebase
    String? result = await _authService.loginStudent(rollNo, password);

    if (result == "Success") {
      // 2. SAVE LOCALLY FIRST (Crucial for the background service filtering)
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save Roll No
      await prefs.setString('user_roll', rollNo);

      // --- NEW LOGIC: FETCH & SAVE ROOM NO ---
      // This fetches the student's room from their Firestore document
      try {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
        if (userDoc.exists && userDoc.data()!.containsKey('roomNo')) {
          String roomNo = userDoc['roomNo'].toString();
          await prefs.setString('user_room', roomNo); // Save it as "311", "112", etc.
          debugPrint("Local room session saved: $roomNo");
        } else {
          debugPrint("Warning: No roomNo found in Firestore for this user.");
        }
      } catch (e) {
        debugPrint("Error fetching room details: $e");
      }

      // 3. Save Token to Cloud (for targeted notifications)
      await saveUserToken(rollNo);

      setState(() => _isLoading = false);

      if (mounted) {
        // 4. Move to Dashboard and clear login stack
        Navigator.pushNamedAndRemoveUntil(context, '/student_app', (route) => false);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $result"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const Icon(Icons.school, size: 80, color: AppStyle.secondaryTeal),
              const SizedBox(height: 10),
              const Text("Student Login",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppStyle.primaryTeal)),
              const SizedBox(height: 40),
              TextField(
                controller: _rollController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Roll Number",
                    prefixIcon: const Icon(Icons.person_outline, color: AppStyle.primaryTeal),
                    labelStyle: const TextStyle(color: AppStyle.primaryTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline, color: AppStyle.primaryTeal),
                    labelStyle: const TextStyle(color: AppStyle.primaryTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyle.secondaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIGN IN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/student_register'),
                child: const Text("New Student? Register Here", style: TextStyle(color: AppStyle.primaryTeal, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}