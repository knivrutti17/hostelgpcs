import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart';

class SettingPage extends StatefulWidget {
  final String rollNo;
  const SettingPage({super.key, required this.rollNo});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handlePasswordChange() async {
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters"))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logic to update the student's private password
      await FirebaseFirestore.instance.collection('users').doc(widget.rollNo).update({
        'customPassword': _passwordController.text.trim(),
        'passwordChanged': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully!"), backgroundColor: Colors.green)
        );
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your default password is your registered mobile number. Change it here for privacy.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePasswordChange,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Update Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}