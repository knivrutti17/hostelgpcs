import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart';

class StudentRegister extends StatefulWidget {
  const StudentRegister({super.key});

  @override
  State<StudentRegister> createState() => _StudentRegisterState();
}

class _StudentRegisterState extends State<StudentRegister> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final MobileAuthService _authService = MobileAuthService();

  String _branch = 'IT';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // UPDATED LOGIC: Account Activation with UID support
  Future<void> _handleRegister() async {
    final String rollInput = _rollController.text.trim();
    final String passwordInput = _passwordController.text.trim();

    if (rollInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your Roll Number and New Password"))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify if student exists in the bulk-uploaded 'users' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(rollInput)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Roll Number not found in Hostel Records. Contact Warden."), backgroundColor: Colors.red)
          );
        }
      } else {
        // 2. Student exists! Update record with private password and UID
        // Setting 'uid' to rollInput ensures screens looking for a UID don't crash
        await FirebaseFirestore.instance.collection('users').doc(rollInput).update({
          'customPassword': passwordInput,
          'passwordChanged': true,
          'status': 'Active',
          'uid': rollInput,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account Activated Successfully!"), backgroundColor: Colors.green)
          );
          // Redirect to login after successful activation
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppStyle.headerGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Container(
                padding: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppStyle.primaryTeal),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text("Activate Account",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppStyle.primaryTeal)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Enter your Roll Number to secure your account with a private password.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    _buildInputField(
                      controller: _rollController,
                      hint: "Roll Number",
                      icon: Icons.badge_outlined,
                    ),
                    _buildInputField(
                      controller: _passwordController,
                      hint: "Create New Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("ACTIVATE ACCOUNT",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppStyle.cardDecoration,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppStyle.primaryTeal, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}