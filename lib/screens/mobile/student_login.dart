import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

class StudentMobileLogin extends StatefulWidget {
  const StudentMobileLogin({super.key});

  @override
  State<StudentMobileLogin> createState() => _StudentMobileLoginState();
}

class _StudentMobileLoginState extends State<StudentMobileLogin> {
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    try {
      String email = "${_rollController.text.trim()}@gpcs.com";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim()
      );
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/student_app', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
                decoration: InputDecoration(
                    labelText: "Roll Number",
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
                  onPressed: _handleLogin,
                  child: const Text("SIGN IN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/student_register'),
                child: const Text("New Student? Register Here", style: TextStyle(color: AppStyle.primaryTeal)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}