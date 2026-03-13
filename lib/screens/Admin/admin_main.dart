import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/widgets.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/admin_overview.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/merit_setup.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/user_logs.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/staff_management.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/manage_contacts.dart';
import 'package:gpcs_hostel_portal/screens/admin/views/blood_donor_list.dart';
import 'package:gpcs_hostel_portal/utils/database_seeder.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Use Index to track view and prevent blinking
  int _currentViewIndex = 0;
  bool _isUploading = false;

  // Map view names to indices for easy navigation from Overview
  final Map<String, int> _viewMap = {
    "Overview": 0,
    "Staff": 1,
    "MeritSetup": 2,
    "Logs": 3,
    "EmergencyContacts": 4,
    "EmergencyBlood": 5,
  };

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
                  child: Container(
                    color: Colors.white,
                    // IndexedStack prevents blinking and preserves scroll positions
                    child: IndexedStack(
                      index: _currentViewIndex,
                      children: [
                        AdminOverview(onSectionChange: (viewName) {
                          setState(() {
                            // If user clicks "Manage Staff" in Overview, switch to Index 1
                            _currentViewIndex = _viewMap[viewName] ?? 0;
                          });
                        }),
                        const StaffManagementView(),
                        MeritSetupForm(),
                        UserLogsView(),
                        const ManageContacts(),
                        const BloodDonorList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sectionHeader("SYSTEM ADMINISTRATION"),
                  _sidebarItem("Dashboard Overview", Icons.dashboard, 0),
                  _sidebarItem("Staff Management", Icons.people_alt, 1),

                  _sectionHeader("ADMISSION CONTROL"),
                  _sidebarItem("Merit List Setup", Icons.list_alt, 2),
                  _sidebarItem("Admission Cut-offs", Icons.percent, -1), // Placeholder

                  _sectionHeader("REPORTS"),
                  _sidebarItem("User Logs", Icons.history, 3),

                  _sectionHeader("EMERGENCY CONTROL"),
                  _sidebarItem("Emergency Contacts", Icons.contact_phone, 4),
                  _sidebarItem("Emergency Blood", Icons.bloodtype, 5),
                ],
              ),
            ),
          ),

          const Divider(),
          _buildInitializeButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _sidebarItem(String title, IconData icon, int index) {
    if (index == -1) return const SizedBox.shrink(); // Safety check

    bool isActive = _currentViewIndex == index;
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
      onTap: () => setState(() => _currentViewIndex = index),
      // Visual feedback for selected item
      selected: isActive,
      selectedTileColor: AppColors.primaryBlue.withOpacity(0.05),
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

  Widget _buildInitializeButton() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton.icon(
        icon: _isUploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_file, size: 18),
        label: Text(_isUploading ? "UPLOADING..." : "INITIALIZE DATABASE", style: const TextStyle(fontSize: 11)),
        onPressed: _isUploading ? null : _runDatabaseSeeder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _runDatabaseSeeder() async {
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
  }
}