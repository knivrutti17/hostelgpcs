import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets.dart';
import '../styles.dart';
import 'hod_complain.dart';
import 'warden/leave_approval.dart'; // Ensure this points to your modular approval file

class HODDashboard extends StatefulWidget {
  const HODDashboard({super.key});

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard> {
  String _selectedPage = 'Dashboard Overview';

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
            marqueeText: "HOD Dashboard Active - Department of Information Technology",
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScrollableSidebar(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(25),
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
    switch (_selectedPage) {
      case 'Dashboard Overview':
        return _buildProfessionalOverview();
      case 'Leave Approvals':
      // Updated to use the professional live approval view
        return const LeaveApprovalView();
      case 'Complaint Box':
        return const HODComplaintView();
      default:
        return Center(child: Text("Section: $_selectedPage Under Development", style: const TextStyle(color: Colors.grey)));
    }
  }

  Widget _buildProfessionalOverview() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HOD Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const Text("Academic Year 2024-25", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 25),

          // 1. TOP STATS HEADER
          Row(
            children: [
              _infoCard("Total Students", "750", Icons.groups, Colors.blue),
              _infoCard("Vacant Rooms", "150", Icons.meeting_room, Colors.blueAccent),

              // LIVE LEAVE REQUEST COUNTER
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('leaves')
                    .where('status', isEqualTo: 'Pending').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";
                  return _infoCard("Leave Requests", count, Icons.approval_outlined, Colors.orange);
                },
              ),

              _infoCard("Complaints", "22", Icons.error_outline, Colors.red),
              _infoCard("Staff On Duty", "5", Icons.work_outline, Colors.purple),
            ],
          ),
          const SizedBox(height: 25),

          // 2. COMPLAINTS & LEAVE TRACKING
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildDashboardSection("Pending Complaints", [
                _complaintRow("Ajay Mehta", "Room B-102", "Critical", Colors.red),
                _complaintRow("Neha Sharma", "Room A-104", "Water Leakage", Colors.orange),
                _complaintRow("Rahul Mishra", "Room A-105", "Medium", Colors.green),
              ])),
              const SizedBox(width: 20),

              // LIVE LEAVE PREVIEW SECTION
              Expanded(flex: 1, child: _buildDashboardSection(
                "Pending Leaves",
                [_buildLiveLeavePreview()],
                onViewAll: () => setState(() => _selectedPage = 'Leave Approvals'),
              )),
            ],
          ),
          const SizedBox(height: 25),

          // 3. IMPORTANT ALERTS & ANNOUNCEMENTS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildDashboardSection("Important Alerts", [
                _alertItem("3 Students Not Returned Today", Colors.red),
                _alertItem("5 Pending Room Cleanings", Colors.orange),
                _alertItem("2 Staff Shift Change Requests", Colors.red),
              ])),
              const SizedBox(width: 1),
              Expanded(flex: 1, child: _buildDashboardSection("Announcements", [
                const Text("Monthly Maintenance inspection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text("All hostel rooms will be inspected tomorrow.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(height: 20),
                const Text("Reminder: Parent Teacher Meeting", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text("Scheduled for April 30 at 11:00 AM.", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW: LIVE LEAVE PREVIEW LOGIC ---
  Widget _buildLiveLeavePreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('leaves')
          .where('status', isEqualTo: 'Pending').limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text("No pending requests", style: TextStyle(fontSize: 12, color: Colors.grey));

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _complaintRow(
                data['studentName'] ?? "Student",
                "Room ${data['roomNo']}",
                data['reason'] ?? "Leave",
                Colors.orange
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 20, child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // UPDATED: Added onViewAll navigation
  Widget _buildDashboardSection(String title, List<Widget> items, {VoidCallback? onViewAll}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              InkWell(
                onTap: onViewAll,
                child: const Text("View All >", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 25),
          ...items,
        ],
      ),
    );
  }

  Widget _complaintRow(String name, String room, String tag, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 15)),
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(room, style: const TextStyle(fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
        child: Text(tag, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _alertItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildScrollableSidebar() {
    return Container(
      width: 300,
      color: AppColors.sidebarBg,
      child: ListView(
        children: [
          _sidebarTitle(" IT STUDENT MONITORING"),
          _sidebarItem("Dashboard Overview", Icons.dashboard_outlined),
          _sidebarItem("View IT Hostelites", Icons.people_outline),
          _sidebarItem("Attendance Reports", Icons.analytics_outlined),
          _sidebarTitle(" DEPARTMENT TOOLS"),
          _sidebarItem("Leave Approvals", Icons.approval_outlined),
          _sidebarItem("Complaint Box", Icons.mail_outline),
        ],
      ),
    );
  }

  Widget _sidebarTitle(String title) {
    return Container(padding: const EdgeInsets.all(12), color: AppColors.primaryBlue, child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)));
  }

  Widget _sidebarItem(String text, IconData icon) {
    bool isSelected = _selectedPage == text;
    return Container(
      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primaryBlue, size: 18),
        title: Text(text, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
        onTap: () => setState(() => _selectedPage = text),
      ),
    );
  }
}