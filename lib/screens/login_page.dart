import 'package:flutter/material.dart';
import '../styles.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- INTEGRATED YOUR SPECIFIC LOGIC START ---
  void _handleLogin() async {
    String email = _emailController.text;
    String pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Show loading indicator
    String? result = await AuthService().loginUser(email, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "ADMIN") {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (result == "WARDEN") {
      Navigator.pushReplacementNamed(context, '/warden');
    } else if (result == "HOD") {
      Navigator.pushReplacementNamed(context, '/hod');
    } else {
      // Show the specific error message returned from AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? "Login Failed"), backgroundColor: Colors.red),
      );
    }
  }
  // --- INTEGRATED YOUR SPECIFIC LOGIC END ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/gpcslogo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 80, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 20),
                const Text(
                  "GPCS HOSTEL PORTAL",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  "Online Management System",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 35),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email / Username",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleLogin,
                    child: const Text(
                      "SIGN IN",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}