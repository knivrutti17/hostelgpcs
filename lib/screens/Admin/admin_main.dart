import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/widgets.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/admin_overview.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/merit_setup.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/user_logs.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/staff_management.dart';
// NEW IMPORTS: Create these files for the Emergency logic
import 'package:gpcs_hostel_portal/screens/admin/views/manage_contacts.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/blood_donor_list.dart';
// IMPORT SEEDER UTILITY
import 'package:gpcs_hostel_portal/utils/database_seeder.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _activeView = "Overview";
  bool _isUploading = false;

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

  // UPDATED: Added cases for Emergency views
  Widget _buildMainContent() {
    switch (_activeView) {
      case "Overview":
        return const AdminOverview();
      case "Staff":
        return const StaffManagementView();
      case "MeritSetup":
        return MeritSetupForm();
      case "Logs":
        return UserLogsView();
      case "EmergencyContacts":
        return const ManageContacts();
      case "EmergencyBlood":
        return const BloodDonorList();
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

          // NEW SECTION: EMERGENCY MANAGEMENT
          _sectionHeader("EMERGENCY CONTROL"),
          _sidebarItem("Emergency Contacts", Icons.contact_phone, "EmergencyContacts"),
          _sidebarItem("Emergency Blood", Icons.bloodtype, "EmergencyBlood"),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(_isUploading ? "UPLOADING..." : "INITIALIZE DATABASE", style: const TextStyle(fontSize: 11)),
              onPressed: _isUploading ? null : () async {
                setState(() => _isUploading = true);
                try {
                  await DatabaseSeeder.uploadStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bulk Student Data Uploaded Successfully!"), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Upload Error: $e"), backgroundColor: Colors.red)
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 10),
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