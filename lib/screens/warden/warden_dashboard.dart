import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets.dart';
import '../../styles.dart';
import 'warden_complaint_view.dart';
import 'merit_setup_view.dart';
import 'leave_approval.dart';
import 'warden_attendance_override.dart'; // NEW: Import for attendance override

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  String _activeSection = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: Column(
        children: [
          buildCommonHeader(),
          buildCommonNavStrip(
            navLinks: [
              navLink("Home", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
              navLink("Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
            ],
            marqueeText: "Warden Dashboard Active - Secure Access Mode",
          ),
          Expanded(
            child: Row(
              children: [
                _buildScrollableSidebar(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: _buildBodyContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_activeSection) {
      case 'Dashboard':
        return _buildProfessionalOverview();
      case 'Merit Setup View':
        return const MeritSetupView();
      case 'Complaint Box':
        return const WardenComplaintView();
      case 'Attendance Override': // NEW: Navigation Case
        return const WardenAttendanceOverride();
      default:
        return Center(child: Text("Section: $_activeSection Under Development", style: const TextStyle(color: Colors.grey)));
    }
  }

  Widget _buildProfessionalOverview() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Warden Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const Text("Academic Year 2024 - 25", style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 25),

          Row(
            children: [
              _infoCard("Total Students", "320", Icons.groups, Colors.blue),
              _infoCard("Total Rooms", "150", Icons.meeting_room, Colors.teal),
              _infoCard("Occupied Rooms", "132", Icons.bed, Colors.teal),
              _infoCard("Vacant Rooms", "18", Icons.single_bed, Colors.red),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('leaves').where('status', isEqualTo: 'Pending').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";
                  return _infoCard("Pending Leave", count, Icons.mail_outline, Colors.orange);
                },
              ),

              _infoCard("Pending Fees", "₹1,32,500", Icons.account_balance_wallet, Colors.brown),
            ],
          ),
          const SizedBox(height: 25),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NEW: Integrated Attendance Override Card
              Expanded(
                  flex: 2,
                  child: _buildDashboardSection(
                    "Attendance Status",
                    _buildAttendanceModule(),
                    onViewAll: () => setState(() => _activeSection = 'Attendance Override'),
                  )
              ),
              const SizedBox(width: 25),

              Expanded(
                  flex: 3,
                  child: _buildDashboardSection(
                    "Pending Leave Requests",
                    _buildLiveLeaveTable(),
                    onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveApprovalView())),
                  )
              ),
            ],
          ),
          const SizedBox(height: 25),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildDashboardSection("Complaints", _buildMiniComplaintFeed())),
              const SizedBox(width: 25),
              Expanded(flex: 1, child: _buildDashboardSection("Hostel Layout", _buildLayoutModule())),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // NEW: Manual Attendance Preview Module
  Widget _buildAttendanceModule() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("85%", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(width: 10),
            Text("Present\nToday", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        const Text("Some students facing GPS issues?", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _activeSection = 'Attendance Override'),
            icon: const Icon(Icons.fact_check_outlined, size: 18, color: Colors.white),
            label: const Text("MANUAL OVERRIDE", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 22, child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(String title, Widget content, {VoidCallback? onViewAll}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              InkWell(
                onTap: onViewAll,
                child: const Text("View All >", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 30),
          content,
        ],
      ),
    );
  }

  Widget _buildLiveAlertList() {
    return Column(
      children: [
        _alertItem("Late Entry: Akshay Jain (A-101)", "11:45 PM", Colors.red),
        _alertItem("Emergency: Water Leakage (B-203)", "11:30 PM", Colors.orange),
        _alertItem("Plumbing: Riya Sharma (B-212)", "11:15 PM", Colors.red),
      ],
    );
  }

  Widget _alertItem(String text, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 22),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLiveLeaveTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('leaves')
          .where('status', isEqualTo: 'Pending')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No pending leaves."));

        return DataTable(
          headingRowHeight: 40,
          horizontalMargin: 0,
          columns: const [
            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Room", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("To", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _leaveRow(data['studentName'] ?? "---", data['roomNo'] ?? "---", data['endDate'] ?? "---", doc.id);
          }).toList(),
        );
      },
    );
  }

  DataRow _leaveRow(String name, String room, String date, String docId) {
    return DataRow(cells: [
      DataCell(Text(name, style: const TextStyle(fontSize: 13))),
      DataCell(Text(room, style: const TextStyle(fontSize: 13))),
      DataCell(Text(date, style: const TextStyle(fontSize: 13))),
      DataCell(ElevatedButton(
          onPressed: () => FirebaseFirestore.instance.collection('leaves').doc(docId).update({'status': 'Approved'}),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text("Approve", style: TextStyle(color: Colors.white, fontSize: 11))
      )),
    ]);
  }

  Widget _buildMiniComplaintFeed() {
    return Column(
      children: [
        _complaintMiniItem("Riya Sharma", "B-212", "23 min ago"),
        _complaintMiniItem("Rahul Mishra", "A-103", "45 min ago"),
        _complaintMiniItem("Aman Singh", "A-105", "1 hour ago"),
      ],
    );
  }

  Widget _complaintMiniItem(String name, String room, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("Room $room", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text("Resolve", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
            Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLayoutModule() {
    return Column(
      children: [
        const Icon(Icons.map_outlined, size: 60, color: Colors.blueGrey),
        const SizedBox(height: 15),
        const Text("View and manage the hostel room occupancy", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.all(15)), child: const Text("View Hostel Layout", style: TextStyle(color: Colors.white)))),
      ],
    );
  }

  Widget _buildScrollableSidebar() {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: ListView(
        children: [
          _sidebarTitle(" Important Links"),
          _sidebarItem("Dashboard", Icons.dashboard_outlined),
          _sidebarItem("Profile Overview", Icons.person_outline),
          _sidebarItem("Merit Setup View", Icons.visibility_outlined),
          _sidebarItem("Complaint Box", Icons.mail_outline),
          _sidebarTitle(" Student Management"),
          _sidebarItem("Student Admission & Allotment", Icons.person_add_outlined),
          _sidebarItem("Student Profile View", Icons.person_search_outlined),
          _sidebarItem("Room & Bed Allocation", Icons.bed_outlined),
          _sidebarTitle(" Attendance Management"), // NEW TITLE
          _sidebarItem("Attendance Override", Icons.fact_check_outlined), // NEW ITEM
          _sidebarTitle(" Room & Hostel Status"),
          _sidebarItem("Vacant Room Status", Icons.meeting_room_outlined),
        ],
      ),
    );
  }

  Widget _sidebarTitle(String title) {
    return Container(padding: const EdgeInsets.all(15), color: AppColors.primaryBlue, child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)));
  }

  Widget _sidebarItem(String text, IconData icon) {
    bool isSelected = _activeSection == text;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: isSelected ? Colors.white : AppColors.primaryBlue, size: 20),
      title: Text(text, style: TextStyle(color: isSelected ? Colors.white : AppColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
      tileColor: isSelected ? AppColors.primaryBlue : Colors.transparent,
      onTap: () => setState(() => _activeSection = text),
    );
  }
}