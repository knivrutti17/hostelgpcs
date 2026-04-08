import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/hod/hod_attendance_reports.dart';
import 'package:gpcs_hostel_portal/screens/hod/hod_dashboard_overview.dart';
import 'package:gpcs_hostel_portal/screens/hod/hod_student_directory.dart';
import 'package:gpcs_hostel_portal/screens/hod_complain.dart';
import 'package:gpcs_hostel_portal/screens/warden/leave_approval.dart';

class HODMainLayout extends StatefulWidget {
  const HODMainLayout({super.key});

  @override
  State<HODMainLayout> createState() => _HODMainLayoutState();
}

class _HODMainLayoutState extends State<HODMainLayout> {
  static const Color _primaryTeal = Color(0xFF438A7F);
  static const String _branch = 'Information technology';

  int _selectedIndex = 0;

  late final List<_HodDestination> _destinations = [
    const _HodDestination(
      label: 'Dashboard Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    const _HodDestination(
      label: 'View IT Hostelites',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    const _HodDestination(
      label: 'Attendance Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    const _HodDestination(
      label: 'Leave Approvals',
      icon: Icons.approval_outlined,
      selectedIcon: Icons.approval_rounded,
    ),
    const _HodDestination(
      label: 'Complaint Box',
      icon: Icons.mail_outline_rounded,
      selectedIcon: Icons.mail_rounded,
    ),
  ];

  late final List<Widget> _pages = [
    const HODDashboardOverview(),
    const HODStudentDirectory(),
    const HODAttendanceReports(),
    const LeaveApprovalView(branchFilter: _branch, showAppBar: false),
    const HODComplaintView(branchFilter: _branch),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: Row(
          children: [
            _buildSideNavigation(context),
            Expanded(
              child: Container(
                color: const Color(0xFFF8FBFA),
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavigation(BuildContext context) {
    final double width = MediaQuery.of(context).size.width < 1100 ? 250 : 280;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.teal.withOpacity(0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryTeal,
                  _primaryTeal.withOpacity(0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'HOD Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Information technology branch',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'MODULES',
              style: TextStyle(
                color: Color(0xFF7A8A86),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final item = _destinations[index];
                final bool isSelected = index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    selected: isSelected,
                    selectedTileColor: _primaryTeal.withOpacity(0.10),
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? _primaryTeal
                          : const Color(0xFF60706C),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? _primaryTeal
                            : const Color(0xFF22312D),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final title = _destinations[_selectedIndex].label;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _primaryTeal.withOpacity(0.10)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20312D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'GPCS Hostel Portal • Academic Year 2025-26',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF72817E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_rounded,
                    color: _primaryTeal, size: 18),
                SizedBox(width: 10),
                Text(
                  'Branch: Information technology',
                  style: TextStyle(
                    color: _primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HodDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _HodDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
