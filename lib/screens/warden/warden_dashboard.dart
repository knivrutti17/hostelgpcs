import 'package:flutter/material.dart';
import '../../widgets.dart';
import '../../styles.dart';
// Ensure this path matches your folder structure
import 'merit_setup_view.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  // State variable to track the active sidebar selection
  String _activeSection = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                // Main Content Area with dynamic switching
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
    switch (_activeSection) {
      case 'Dashboard':
        return const Center(
            child: Text(
                "Welcome to Warden Management System",
                style: TextStyle(color: Colors.grey, fontSize: 18)
            )
        );
      case 'Merit Setup View':
      // This calls the separate read-only file created for the Warden
        return const MeritSetupView();
      default:
        return Center(
            child: Text(
                "Section: $_activeSection Under Development",
                style: const TextStyle(color: Colors.grey)
            )
        );
    }
  }

  // --- SIDEBAR UI ---
  Widget _buildScrollableSidebar() {
    return Container(
      width: 300,
      color: AppColors.sidebarBg,
      child: ListView(
        children: [
          _sidebarTitle(" Important Links"),
          _sidebarItem("Dashboard", Icons.dashboard_outlined),
          _sidebarItem("Profile Overview", Icons.person_outline),

          // Link to the read-only view saved in merit_setup_view.dart
          _sidebarItem("Merit Setup View", Icons.visibility_outlined),

          _sidebarTitle(" Student Management"),
          _sidebarItem("Student Admission & Allotment", Icons.person_add_outlined),
          _sidebarItem("Student Profile View", Icons.person_search_outlined),
          _sidebarItem("Room & Bed Allocation", Icons.bed_outlined),

          _sidebarTitle(" Room & Hostel Status"),
          _sidebarItem("Vacant Room Status", Icons.meeting_room_outlined),
        ],
      ),
    );
  }

  Widget _sidebarTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryBlue,
      child: Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12
          )
      ),
    );
  }

  Widget _sidebarItem(String text, IconData icon) {
    bool isSelected = _activeSection == text;
    return ListTile(
      dense: true,
      leading: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.primaryBlue,
          size: 20
      ),
      title: Text(
          text,
          style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.bold
          )
      ),
      // Background color changes based on selection
      tileColor: isSelected ? AppColors.primaryBlue : Colors.transparent,
      onTap: () {
        setState(() {
          _activeSection = text;
        });
      },
    );
  }
}