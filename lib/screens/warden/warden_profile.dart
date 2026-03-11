import 'package:flutter/material.dart';

class WardenProfile extends StatelessWidget {
  const WardenProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Warden Profile Overview",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 25),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE SECTION
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/warden1.png', // PATH MUST MATCH PUBSPEC EXACTLY
                    width: 150,
                    height: 180,
                    fit: BoxFit.cover,
                    // Error builder prevents the "Unable to load asset" red screen
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 150,
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 30),

                // DETAILS SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mr. Ashok Patil",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Warden",
                        style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 25),
                      _buildInfoRow("Employee ID:", "GP1234"),
                      _buildInfoRow("Contact:", "+91 987543210"),
                      _buildInfoRow("Email:", "ashokpatil@gpp.edu.in"),
                      _buildInfoRow("Hostel Block Assigned:", "A-Block"),
                      _buildInfoRow("Joining Date:", "01/02/2021"),
                    ],
                  ),
                ),

                // EDUCATION & EXPERIENCE SECTION
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Education", Colors.blue),
                      _buildBulletItem("M.A. in Education Administration"),
                      _buildBulletItem("Bachelor's Degree in Arts"),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Experience", Colors.green),
                      _buildBulletItem("10+ Years in Hostel Administration"),
                      _buildBulletItem("Former Assistant Warden – XYZ Hostel"),
                      _buildBulletItem("Student Welfare Coordinator"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "About",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          const Text(
            "Mr. Ashok Patil serves as the Warden of A-Block at the Boys Hostel of Government Polytechnic, Chhatrapati Sambhajinagar. He is responsible for maintaining hostel discipline, supervising student activities, ensuring safety, and managing daily hostel operations including room allocation, leave approvals, and complaint handling.",
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Text(
            "He holds a Master's degree in Education Administration and has over 10 years of experience in hostel and student welfare management. With strong leadership and organizational skills, he ensures a secure, disciplined, and supportive residential environment for all hostel students.",
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}