import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/hod/hod_attendance_reports.dart';
import 'package:gpcs_hostel_portal/screens/hod/hod_student_directory.dart';
import 'package:gpcs_hostel_portal/screens/hod_complain.dart';
import 'package:gpcs_hostel_portal/screens/warden/leave_approval.dart';

import '../styles.dart';
import '../widgets.dart';

class HODDashboard extends StatefulWidget {
  const HODDashboard({super.key});

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard> {
  static const String _branch = 'Information technology';
  static const int _totalRooms = 150;

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
              navLink(
                "Home",
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
              ),
              navLink(
                "Log Out",
                () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
              ),
            ],
            marqueeText:
                "HOD Dashboard Active - Department of Information Technology",
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
      case 'View IT Hostelites':
        return const HODStudentDirectory();
      case 'Attendance Reports':
        return const HODAttendanceReports();
      case 'Leave Approvals':
        return const LeaveApprovalView(
          branchFilter: _branch,
          showAppBar: false,
        );
      case 'Complaint Box':
        return const HODComplaintView(branchFilter: _branch);
      default:
        return Center(
          child: Text(
            "Section: $_selectedPage Under Development",
            style: const TextStyle(color: Colors.grey),
          ),
        );
    }
  }

  Widget _buildProfessionalOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (!studentSnapshot.hasData) {
          return const Center(child: LinearProgressIndicator());
        }

        final users = studentSnapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == _branch;
        }).toList();
        final int totalStudents = users.length;
        final Set<String> occupiedRoomSet = users
            .map((doc) => (doc.data() as Map<String, dynamic>)['roomNo']
                    ?.toString() ??
                "")
            .where((room) => room.isNotEmpty)
            .toSet();
        final int vacantRooms = (_totalRooms - occupiedRoomSet.length) < 0
            ? 0
            : (_totalRooms - occupiedRoomSet.length);

        final Set<String> itStudentIds = users
            .map((doc) => doc.id)
            .where((id) => id.isNotEmpty)
            .toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leaves')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, leaveSnapshot) {
            final int pendingLeaves = leaveSnapshot.hasData
                ? leaveSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final studentId =
                        (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                            .toString();
                    return itStudentIds.contains(studentId);
                  }).length
                : 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, complaintSnapshot) {
                final int pendingComplaints = complaintSnapshot.hasData
                    ? complaintSnapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final studentId =
                            (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                                .toString();
                        return itStudentIds.contains(studentId);
                      }).length
                    : 0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HOD Dashboard",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const Text(
                        "Academic Year 2025-26",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          _infoCard(
                            "Total IT Students",
                            totalStudents.toString(),
                            Icons.groups,
                            Colors.blue,
                          ),
                          _infoCard(
                            "Vacant Rooms (IT)",
                            vacantRooms.toString(),
                            Icons.meeting_room,
                            Colors.blueAccent,
                          ),
                          _infoCard(
                            "Pending Leaves",
                            pendingLeaves.toString(),
                            Icons.approval_outlined,
                            Colors.orange,
                          ),
                          _infoCard(
                            "Open Complaints",
                            pendingComplaints.toString(),
                            Icons.error_outline,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDashboardSection(
                              "Pending Complaints",
                              [_buildLiveComplaintPreview()],
                              onViewAll: () =>
                                  setState(() => _selectedPage = 'Complaint Box'),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDashboardSection(
                              "Pending Leaves",
                              [_buildLiveLeavePreview()],
                              onViewAll: () => setState(
                                () => _selectedPage = 'Leave Approvals',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLiveComplaintPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final itStudentIds = userSnapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == _branch;
        }).map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('complaints')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentId =
                  (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                      .toString();
              return itStudentIds.contains(studentId);
            }).take(3).toList();

            if (docs.isEmpty) {
              return const Text(
                "No pending complaints",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final urgency = (data['urgency'] ?? 'Medium').toString();
                return _complaintRow(
                  data['studentName'] ?? "Student",
                  "Room ${data['roomNo'] ?? '--'}",
                  urgency,
                  _badgeColorForUrgency(urgency),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveLeavePreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final itStudentIds = userSnapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == _branch;
        }).map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leaves')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentId =
                  (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                      .toString();
              return itStudentIds.contains(studentId);
            }).take(3).toList();

            if (docs.isEmpty) {
              return const Text(
                "No pending requests",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _complaintRow(
                  data['studentName'] ?? "Student",
                  "Room ${data['roomNo'] ?? '--'}",
                  data['reason'] ?? "Leave",
                  Colors.orange,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Color _badgeColorForUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _infoCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              val,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(
    String title,
    List<Widget> items, {
    VoidCallback? onViewAll,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  "View All >",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      leading: const CircleAvatar(
        radius: 15,
        child: Icon(Icons.person, size: 15),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(room, style: const TextStyle(fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryBlue,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _sidebarItem(String text, IconData icon) {
    final bool isSelected = _selectedPage == text;
    return Container(
      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primaryBlue, size: 18),
        title: Text(
          text,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => setState(() => _selectedPage = text),
      ),
    );
  }
}
