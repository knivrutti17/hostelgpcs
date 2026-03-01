import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        bool isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Admin Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const Text("Academic Year 2024-25",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 25),

            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _infoCard("Total Students", "950", Icons.groups, Colors.blue, constraints.maxWidth),
                _infoCard("Vacant Rooms", "120", Icons.meeting_room, Colors.blueAccent, constraints.maxWidth),
                _infoCard("Active Complaints", "28", Icons.error_outline, Colors.red, constraints.maxWidth),
                _infoCard("Staff On Duty", "5", Icons.assignment_ind, Colors.purple, constraints.maxWidth),
                _infoCard("Pending Fees", "₹ 98,500", Icons.account_balance_wallet, Colors.orange, constraints.maxWidth),
              ],
            ),
            const SizedBox(height: 25),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _quickAction("Add New Student", Icons.person_add, Colors.blue, isMobile, () {}),
                _quickAction("Manage Rooms", Icons.bed, Colors.indigo, isMobile, () {}),
                _quickAction("Attendance Setup", Icons.location_on, Colors.deepPurple, isMobile, () {
                  Navigator.pushNamed(context, '/attendance_setup');
                }),
                _quickAction("View Reports", Icons.analytics, Colors.redAccent, isMobile, () {}),
                _quickAction("Manage Staff", Icons.people, Colors.orange, isMobile, () {}),
              ],
            ),
            const SizedBox(height: 30),

            _buildResponsiveGrid(isMobile, isTablet),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveGrid(bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _buildSectionCard("Pending Complaints", _buildComplaintList()),
        _buildSectionCard("Hostel Room Overview", _buildRoomPreview()),
        _buildSectionCard("Announcements", _buildAnnouncements()),
        _buildSectionCard("Fee Collection", _buildFeeChart()),
        _buildSectionCard("Visitors Today", _buildVisitorList()),
        _buildSectionCard("Attendance Overview", _buildAttendanceGrid()),
      ],
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color color, double screenWidth) {
    double width = screenWidth > 1200 ? (screenWidth - 160) / 5 : (screenWidth > 800 ? (screenWidth - 100) / 2 : screenWidth - 40);

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 22, child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 15),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, bool isMobile, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              TextButton(onPressed: () {}, child: const Text("View All >", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 25),
          Expanded(child: content),
        ],
      ),
    );
  }

  // --- LIVE ATTENDANCE GRID ---
  Widget _buildAttendanceGrid() {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    const int totalStudents = 950;

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('daily_attendance')
            .where('date', isEqualTo: todayDate) // Efficient filtering
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LinearProgressIndicator());

          int presentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          int absentCount = totalStudents - presentCount;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 16),
                  SizedBox(width: 5),
                  Text("Geofence Active: 100m",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attendMiniStat("Present", "$presentCount Students", Colors.blue),
                  _attendMiniStat("Absent", "$absentCount Students", Colors.red),
                ],
              ),
            ],
          );
        }
    );
  }

  Widget _attendMiniStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // Placeholder static methods preserved for UI consistency
  Widget _buildComplaintList() => const Text("Ajay Mehta - Room B-102 (Critical)");
  Widget _buildFeeChart() => const Icon(Icons.show_chart, size: 60, color: Colors.green);
  Widget _buildRoomPreview() => const Icon(Icons.map_outlined, size: 60, color: Colors.blueGrey);
  Widget _buildVisitorList() => const Text("Ravindra Patil - 11:00 AM");
  Widget _buildAnnouncements() => const Text("Maintenance inspection on April 25");
}