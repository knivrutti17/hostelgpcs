import 'package:flutter/material.dart';
import '../widgets.dart';
import '../styles.dart';
import '../services/auth_service.dart';
// Note: Dashboards are now handled via named routes in main.dart

class PortalPage extends StatefulWidget {
  const PortalPage({super.key});

  @override
  State<PortalPage> createState() => _PortalPageState();
}

class _PortalPageState extends State<PortalPage> {
  bool isLoginVisible = false;
  bool _isLoading = false;

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- UPDATED LOGIN LOGIC TO FIX COMPILATION ERROR ---
  Future<void> _handlePortalLogin() async {
    String email = _userController.text.trim();
    String password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both User Name and Password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // FIXED: Changed 'loginAndGetRole' to 'loginUser' to match AuthService
    String? role = await AuthService().loginUser(email, password);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (role != null) {
      // Normalize role to uppercase to match logic
      String normalizedRole = role.toUpperCase();

      // Redirection based on Admin, Warden, or HOD role using named routes
      if (normalizedRole == 'ADMIN') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (normalizedRole == 'WARDEN') {
        Navigator.pushReplacementNamed(context, '/warden');
      } else if (normalizedRole == 'HOD') {
        Navigator.pushReplacementNamed(context, '/hod');
      } else {
        // If role exists but isn't recognized
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Access Denied: Role '$role' unauthorized")),
        );
      }
    } else {
      // result is null if auth failed or record missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Credentials or Access Denied")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          buildCommonHeader(),
          buildCommonNavStrip(
            navLinks: [
              navLink("Home", () => setState(() => isLoginVisible = false)),
              navLink("Contact", () {}),
              navLink("Log In", () => setState(() => isLoginVisible = true)),
            ],
            marqueeText: "Welcome to Government Polytechnic Chhatrapati Sambhajinagar ERP Portal, by NIVRUTTI KAKDE",
          ),
          Expanded(
            child: Row(
              children: [
                _buildSimpleSidebar(),
                Expanded(
                  child: Center(
                    child: isLoginVisible ? _buildOriginalLoginCard() : _buildWelcomeText(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSidebar() {
    return Container(
      width: 250,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.primaryBlue,
            child: const Text("IMPORTANT LINKS", style: AppStyles.sidebarHeader),
          ),
          ListTile(
              title: const Text("About Us",
                  style: TextStyle(color: AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.bold))
          ),
          ListTile(
              title: const Text("Official Website",
                  style: TextStyle(color: AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Center(
      child: Text(
        "Welcome to Government Polytechnic Chhatrapati Sambhajinagar ERP Portal",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOriginalLoginCard() {
    return Container(
      width: 500,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.loginHeader, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.loginHeader,
            child: const Center(child: Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: "User Name/Email", border: OutlineInputBorder())
                ),
                const SizedBox(height: 15),
                TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.loginHeader)
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF390777),
                    minimumSize: const Size(150, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _handlePortalLogin,
                  child: const Text("Login", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}