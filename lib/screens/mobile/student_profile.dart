import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/services/mobile_auth_service.dart';
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/idcard_generate.dart';
import 'package:gpcs_hostel_portal/screens/mobile/profile_edit.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  Future<String?> _getRollNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_roll');
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
              backgroundColor: const Color(0xFFF8F9FE),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildModernHeader(data),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 2.1,
                            children: [
                              _infoCard(Icons.assignment_outlined, "Roll Number", data['rollNo'] ?? '---'),
                              _infoCard(Icons.business_center_outlined, "Branch", data['department'] ?? 'IT'),
                              _infoCard(Icons.category_outlined, "Category", data['category'] ?? 'Open'),
                              _infoCard(Icons.home_outlined, "Hostel", data['hostel'] ?? 'Devgiri'),
                              _infoCard(Icons.phone_outlined, "Contact", data['contact'] ?? '---'),
                              _infoCard(Icons.meeting_room_outlined, "Room Number", data['roomNo']?.toString() ?? '---'),
                              _infoCard(Icons.bloodtype_outlined, "Blood Group", data['bloodGroup'] ?? '---'),
                              _infoCard(Icons.hotel_outlined, "Hostel", data['hostel'] ?? 'Devgiri'),
                            ],
                          ),
                          const SizedBox(height: 25),
                          _buildQuickActions(context, data),
                          const SizedBox(height: 20),
                          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 10),
                          _actionRow(Icons.edit_outlined, "Edit Profile", () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEdit(studentData: data)));
                          }),
                          const SizedBox(height: 12),
                          _actionRow(Icons.badge_outlined, "Download ID Card", () async {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating ID Card..."), duration: Duration(seconds: 2)));
                            await IDCardGenerator.generateAndDownloadIDCard(data);
                          }
                          ),
                          const SizedBox(height: 12),
                          _logoutButton(context),
                          const SizedBox(height: 40),
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

  Widget _buildModernHeader(Map<String, dynamic> data) {
    Uint8List? imageBytes;
    // Decodes the Base64 string from Firestore into bytes for display
    if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
      try {
        imageBytes = base64Decode(data['photoUrl']);
      } catch (e) {
        debugPrint("Error decoding image: $e");
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFFF8F9FE)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFFF1F4F9),
              // Use MemoryImage to render the decoded bytes
              backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null ? const Icon(Icons.person, size: 70, color: Color(0xFFBCC6D1)) : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(data['name'] ?? 'Student Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
          Text("Roll No: ${data['rollNo'] ?? '---'}", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF438A7F), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickActionBtn(Icons.edit_note, "Edit Profile", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEdit(studentData: data)));
        }),
        _quickActionBtn(Icons.lock_reset, "Change PW", () {}),
        _quickActionBtn(Icons.badge_outlined, "ID Card", () async => await IDCardGenerator.generateAndDownloadIDCard(data)),
      ],
    );
  }

  Widget _quickActionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: Icon(icon, color: const Color(0xFF438A7F), size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF438A7F), size: 20),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4F4F4F))),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final MobileAuthService auth = MobileAuthService();
        await auth.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile_login', (route) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new, color: Colors.redAccent, size: 22),
            SizedBox(width: 12),
            Text("Logout", style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 30),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}