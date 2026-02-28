import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart'; // Import the new service

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
  final MobileAuthService _authService = MobileAuthService(); // Initialize Service

  String _branch = 'IT';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    // Call registration logic using mobile service
    String? result = await _authService.registerStudent(
      name: _nameController.text.trim(),
      rollNo: _rollController.text.trim(),
      password: _passwordController.text.trim(),
      contact: _contactController.text.trim(),
      branch: _branch,
    );

    setState(() => _isLoading = false);

    if (result == "Success") {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/student_app', (route) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $result")));
      }
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
                        const Text("Student Registration",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppStyle.primaryTeal)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildInputField(
                      controller: _nameController,
                      hint: "Full Name",
                      icon: Icons.person_outline,
                    ),
                    _buildInputField(
                      controller: _rollController,
                      hint: "Roll Number",
                      icon: Icons.badge_outlined,
                    ),
                    _buildInputField(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    _buildInputField(
                      controller: _contactController,
                      hint: "Contact Number",
                      icon: Icons.phone_outlined,
                    ),
                    _buildBranchDropdown(),
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
                            : const Text("REGISTER",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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

  // UI helper methods remain unchanged as per request
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

  Widget _buildBranchDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppStyle.cardDecoration,
      child: DropdownButtonFormField<String>(
        value: _branch,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.school_outlined, color: AppStyle.primaryTeal, size: 22),
          border: InputBorder.none,
          hintText: "Branch",
        ),
        items: ['IT', 'Civil', 'Mech', 'Electrical']
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (v) => setState(() => _branch = v!),
      ),
    );
  }
}