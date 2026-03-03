import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart'; // To use your signout logic

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  // Helper function to get the stored Roll Number
  Future<String?> _getRollNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_roll'); // Matches key in MobileAuthService
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getRollNo(),
      builder: (context, rollSnapshot) {
        if (rollSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final String? rollNo = rollSnapshot.data;

        // Fetch document using Roll Number as the ID
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(rollNo).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Profile data not found"));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;

            return Scaffold(
              backgroundColor: AppStyle.bgWhite,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(data),
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _profileInfoTile(
                            icon: Icons.assignment_outlined,
                            label: "Roll Number",
                            value: data['rollNo'] ?? 'N/A',
                          ),
                          _profileInfoTile(
                            icon: Icons.business_center_outlined,
                            label: "Branch",
                            value: data['branch'] ?? 'N/A',
                          ),
                          _profileInfoTile(
                            icon: Icons.category_outlined,
                            label: "Category",
                            value: data['category'] ?? 'N/A',
                          ),
                          _profileInfoTile(
                            icon: Icons.phone_outlined,
                            label: "Contact",
                            value: data['contact'] ?? 'N/A',
                          ),
                          const SizedBox(height: 20),
                          _buildLogoutButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppStyle.headerGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          top: 100,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE0E0FF),
                  child: Icon(Icons.person, size: 60, color: Color(0xFF7C7CFF)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data['name'] ?? 'Student Name',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                "Roll No: ${data['rollNo'] ?? 'N/A'}",
                style: const TextStyle(color: AppStyle.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final MobileAuthService auth = MobileAuthService();
        await auth.signOut(); // Clears SharedPreferences
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile_login', (route) => false);
        }
      },
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: const Text("Logout", style: TextStyle(color: AppStyle.textGrey, fontSize: 16)),
    );
  }

  Widget _profileInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyle.cardDecoration,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppStyle.accentTeal, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppStyle.primaryTeal),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: AppStyle.textGrey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: AppStyle.textGrey),
      ),
    );
  }
}