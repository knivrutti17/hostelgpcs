import 'package:flutter/material.dart';
import '../widgets.dart'; //
import '../styles.dart';  //

class HODDashboard extends StatefulWidget {
  const HODDashboard({super.key});

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard> {
  // State variable to track the active sidebar selection
  String _selectedPage = 'Dashboard Overview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. ORIGINAL TOP HEADER
          buildCommonHeader(),

          // 2. COMMON NAVIGATION STRIP
          buildCommonNavStrip(
            navLinks: [
              navLink("Home", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
              navLink("Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
            ],
            marqueeText: "HOD Dashboard Active - Department of Information Technology - Secure Mode",
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. SCROLLABLE SIDEBAR
                _buildScrollableSidebar(),

                // 4. DYNAMIC CONTENT AREA
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    color: Colors.white,
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

  // --- DYNAMIC CONTENT SWITCHER ---
  Widget _buildBodyContent() {
    switch (_selectedPage) {
      case 'Dashboard Overview':
        return _buildOverviewGrid();
      case 'Leave Approvals':
        return _buildLeavePortal();
      case 'Complaint Box':
        return const Center(child: Text("No Pending Complaints for IT Department.", style: TextStyle(color: Colors.grey)));
      default:
        return Center(child: Text("Section: $_selectedPage Under Development", style: const TextStyle(color: Colors.grey)));
    }
  }

  // --- FEATURE: HOD OVERVIEW GRID ---
  Widget _buildOverviewGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("IT Department Student Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 25),
        Row(
          children: [
            _statCard("Total IT Boys", "45", Colors.redAccent),
            _statCard("Total IT Girls", "38", Colors.redAccent),
            _statCard("Leave Requests", "03", Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String count, Color accentColor) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 25),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5), // Light purple background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }

  // --- FEATURE: LEAVE PORTAL ---
  Widget _buildLeavePortal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pending Leave Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: AppColors.primaryBlue),
            title: const Text("Student: Rahul S. (TY-IT)"),
            subtitle: const Text("Reason: Sickness | Dates: Feb 18 - Feb 20"),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Approve"),
            ),
          ),
        ),
      ],
    );
  }

  // --- SIDEBAR WIDGETS ---
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
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryBlue,
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _sidebarItem(String text, IconData icon) {
    bool isSelected = _selectedPage == text;
    return Container(
      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primaryBlue, size: 18),
        title: Text(text, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
        onTap: () {
          setState(() => _selectedPage = text);
        },
      ),
    );
  }
}