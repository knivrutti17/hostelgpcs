import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOverview extends StatelessWidget {
  final Function(String)? onSectionChange;

  const AdminOverview({super.key, this.onSectionChange});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        bool isTablet = constraints.maxWidth >= 800 && constraints.maxWidth < 1200;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Admin Dashboard",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const Text("Academic Year 2025-26",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 25),

              // --- TOP STATS ROW (REAL-TIME DATA) ---
              _buildLiveStatsRow(constraints.maxWidth),

              const SizedBox(height: 25),

              // --- QUICK ACTIONS ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _quickAction("Add New Student", Icons.person_add, Colors.blue, isMobile, () {
                    if (onSectionChange != null) onSectionChange!('Student Admission');
                  }),
                  _quickAction("Manage Rooms", Icons.bed, Colors.indigo, isMobile, () {
                    if (onSectionChange != null) onSectionChange!('Room Allocation');
                  }),
                  _quickAction("Attendance Setup", Icons.location_on, Colors.deepPurple, isMobile, () {
                    Navigator.pushNamed(context, '/attendance_setup');
                  }),
                  _quickAction("View Reports", Icons.analytics, Colors.redAccent, isMobile, () {}),
                  _quickAction("Manage Staff", Icons.people, Colors.orange, isMobile, () {
                    if (onSectionChange != null) onSectionChange!('Staff Management');
                  }),
                ],
              ),
              const SizedBox(height: 30),

              _buildResponsiveGrid(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  // --- DYNAMIC LIVE STATS LOGIC (FIXED ERRORS HERE) ---
  Widget _buildLiveStatsRow(double maxWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('complaints').where('status', isEqualTo: 'Open').snapshots(),
          builder: (context, complaintSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('hostels').snapshots(),
              builder: (context, hostelSnap) {

                int totalStudents = 0;
                int totalStaff = 0;
                if (userSnap.hasData) {
                  for (var doc in userSnap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    var role = data['role']?.toString().toLowerCase();
                    if (role == 'student') totalStudents++;
                    if (role == 'warden' || role == 'hod') totalStaff++;
                  }
                }

                // FIXED: Used 'hostelSnap' correctly and handled 'num' to 'int' conversion
                int vacantRooms = 0;
                if (hostelSnap.hasData) {
                  for (var doc in hostelSnap.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    // Cast to num first, then call toInt() to prevent type errors
                    vacantRooms += (data['vacantSeats'] as num? ?? 0).toInt();
                  }
                }

                int activeComplaints = complaintSnap.hasData ? complaintSnap.data!.docs.length : 0;

                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _infoCard("Total Students", totalStudents.toString(), Icons.groups, Colors.blue, maxWidth),
                    _infoCard("Vacant Seats", vacantRooms.toString(), Icons.meeting_room, Colors.blueAccent, maxWidth),
                    _infoCard("Active Complaints", activeComplaints.toString(), Icons.error_outline, Colors.red, maxWidth),
                    _infoCard("Staff Count", totalStaff.toString(), Icons.assignment_ind, Colors.purple, maxWidth),
                    _infoCard("Pending Fees", "₹ 1800", Icons.account_balance_wallet, Colors.orange, maxWidth),
                  ],
                );
              },
            );
          },
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
        _buildSectionCard("Recent Complaints", _buildComplaintList()),
        _buildSectionCard("Announcements", _buildAnnouncements()),
        _buildSectionCard("Attendance Overview", _buildAttendanceGrid()),
        _buildSectionCard("Hostel Room Overview", _buildRoomPreview()),
        _buildSectionCard("Fee Collection Status", _buildFeeChart()),
        _buildSectionCard("Visitors Log", _buildVisitorList()),
      ],
    );
  }

  Widget _buildComplaintList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').orderBy('timestamp', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No complaints found", style: TextStyle(fontSize: 12, color: Colors.grey)));

        return Column(
          children: docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.1), radius: 14, child: const Icon(Icons.warning, size: 14, color: Colors.red)),
              title: Text(data['studentName'] ?? "Anonymous", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text("Room: ${data['roomNo'] ?? '--'} • ${data['type'] ?? 'Issue'}", style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnnouncements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notices').orderBy('timestamp', descending: true).limit(2).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No recent announcements", style: TextStyle(fontSize: 12)));

        return Column(
          children: docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: Text(data['title'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAttendanceGrid() {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('daily_attendance').where('date', isEqualTo: todayDate).snapshots(),
            builder: (context, attendSnap) {
              int total = userSnap.hasData ? userSnap.data!.docs.length : 0;
              int present = attendSnap.hasData ? attendSnap.data!.docs.length : 0;
              int absent = total - present;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.green, size: 14),
                      const SizedBox(width: 5),
                      Text("Today: ${DateFormat('dd MMM').format(DateTime.now())}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _attendMiniStat("Present", present.toString(), Colors.blue),
                      _attendMiniStat("Absent", absent.toString(), Colors.red),
                    ],
                  ),
                ],
              );
            },
          );
        }
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color color, double screenWidth) {
    double width = screenWidth > 1200 ? (screenWidth - 380) / 5 : (screenWidth > 800 ? (screenWidth - 100) / 2 : screenWidth - 48);

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
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
              TextButton(onPressed: () {}, child: const Text("View All >", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 20),
          Expanded(child: content),
        ],
      ),
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

  Widget _buildFeeChart() => const Center(child: Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey));
  Widget _buildRoomPreview() => const Center(child: Icon(Icons.map_outlined, size: 40, color: Colors.blueGrey));
  Widget _buildVisitorList() => const Center(child: Text("Log empty for today", style: TextStyle(fontSize: 11, color: Colors.grey)));
}