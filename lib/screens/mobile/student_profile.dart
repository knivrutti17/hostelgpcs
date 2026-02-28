import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart'; // Import central styles

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Profile data not found"));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: AppStyle.bgWhite, // Use themed background
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Professional Header with Profile Image
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: AppStyle.headerGradient, // Header matches dashboard
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Color(0xFFE0E0FF),
                              child: Icon(Icons.person, size: 60, color: Color(0xFF7C7CFF)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Student Name and Roll Number
                          Text(
                            data['name'] ?? 'Kakde',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Consistent text color
                            ),
                          ),
                          Text(
                            "Roll No: ${data['rollNo'] ?? '555555'}",
                            style: const TextStyle(color: AppStyle.textGrey), // Themed text
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Spacing for overlapping profile

                // Detailed Info Tiles pulling from Central Style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _profileInfoTile(
                        icon: Icons.assignment_outlined,
                        label: "Roll Number",
                        value: data['rollNo'] ?? '555555',
                      ),
                      _profileInfoTile(
                        icon: Icons.business_center_outlined,
                        label: "Branch",
                        value: data['branch'] ?? 'IT',
                      ),
                      _profileInfoTile(
                        icon: Icons.category_outlined,
                        label: "Category",
                        value: data['category'] ?? 'Open',
                      ),
                      _profileInfoTile(
                        icon: Icons.phone_outlined,
                        label: "Contact",
                        value: data['contact'] ?? '8787563478',
                      ),

                      const SizedBox(height: 20),

                      // Logout Button matching UI requirements
                      TextButton.icon(
                        onPressed: () => FirebaseAuth.instance.signOut().then((_) {
                          Navigator.pushNamedAndRemoveUntil(context, '/mobile_login', (route) => false);
                        }),
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: AppStyle.textGrey, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyle.cardDecoration, // Themed container decoration
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.accentTeal, // Themed icon background
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppStyle.primaryTeal), // Themed icon
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppStyle.textGrey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppStyle.textGrey),
      ),
    );
  }
}