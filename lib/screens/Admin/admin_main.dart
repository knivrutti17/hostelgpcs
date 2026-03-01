import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/widgets.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/admin_overview.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/merit_setup.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/user_logs.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/staff_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _activeView = "Overview";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          buildCommonHeader(),
          buildCommonNavStrip(
            navLinks: [
              navLink("Home", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
              navLink("Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false)),
            ],
            marqueeText: "ADMIN PANEL: HOSTEL SEAT ALLOCATION & MERIT CONTROL ACTIVE",
          ),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeView) {
      case "Overview":
        return const AdminOverview(); // Calling the live aggregated view
      case "Staff":
        return const StaffManagementView();
      case "MeritSetup":
        return MeritSetupForm();
      case "Logs":
        return UserLogsView();
      default:
        return const AdminOverview();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _sectionHeader("SYSTEM ADMINISTRATION"),
          _sidebarItem("Dashboard Overview", Icons.dashboard, "Overview"),
          _sidebarItem("Staff Management", Icons.people_alt, "Staff"),
          _sectionHeader("ADMISSION CONTROL"),
          _sidebarItem("Merit List Setup", Icons.list_alt, "MeritSetup"),
          _sidebarItem("Admission Cut-offs", Icons.percent, "Cutoffs"),
          _sectionHeader("REPORTS"),
          _sidebarItem("User Logs", Icons.history, "Logs"),
        ],
      ),
    );
  }

  Widget _sidebarItem(String title, IconData icon, String viewName) {
    bool isActive = _activeView == viewName;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.primaryBlue : Colors.grey),
      title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primaryBlue : AppColors.textBlack,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )
      ),
      onTap: () => setState(() => _activeView = viewName),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryBlue,
      child: Text(title, style: AppStyles.sidebarHeader),
    );
  }
}