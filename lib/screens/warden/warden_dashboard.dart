import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets.dart';
import '../../styles.dart';
import 'warden_complaint_view.dart';
import 'merit_setup_view.dart';
import 'leave_approval.dart';
import 'warden_attendance_override.dart';
import 'all_students_view.dart';
import 'warden_profile.dart';
import 'mess_menu_management.dart'; // IMPORT YOUR NEW FILE
import 'package:gpcs_hostel_portal/screens/warden/warden_attendance_reports.dart';
import 'package:gpcs_hostel_portal/services/chat_control_service.dart';
import 'package:gpcs_hostel_portal/screens/mobile/chat/chat_list_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  String _activeSection = 'Dashboard';
  final ChatControlService _chatControlService = ChatControlService();

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
                      context, '/', (route) => false)),
              navLink(
                  "Log Out",
                  () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false)),
            ],
            marqueeText: "Warden Dashboard Active - Secure Access Mode",
          ),
          Expanded(
            child: Row(
              children: [
                _buildScrollableSidebar(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
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
      case 'Profile Overview':
        return const WardenProfile();
      case 'Merit Setup View':
        return const MeritSetupView();
      case 'Complaint Box':
        return const WardenComplaintView();
      case 'Attendance Override':
        return const WardenAttendanceOverride();
      case 'Attendance Reports':
        return const WardenAttendanceReports();
      case 'Leave Requests':
        return const LeaveApprovalView();
      case 'Hostel Chat':
        return const ChatListScreen();
      case 'Student Management':
        return const AllStudentsView();
      // --- REQUIREMENT: MESS MENU CASE ---
      case 'Mess Menu':
        return const MessMenuManagement();
      default:
        return Center(
            child: Text("Section: $_activeSection Under Development",
                style: const TextStyle(color: Colors.grey)));
    }
  }

  Widget _buildProfessionalOverview() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: LinearProgressIndicator());

          var users = snapshot.data!.docs;
          int totalStudents =
              users.where((doc) => doc['role'] == 'student').length;

          Set<String> occupiedRoomSet = users
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['roomNo']?.toString() ??
                  "")
              .where((room) => room.isNotEmpty)
              .toSet();

          int totalRooms = 150;
          int occupiedRooms = occupiedRoomSet.length;
          int vacantRooms = (totalRooms - occupiedRooms) < 0
              ? 0
              : (totalRooms - occupiedRooms);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Warden Dashboard",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const Text("Academic Year 2025 - 26",
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _infoCard("Total Students", totalStudents.toString(),
                        Icons.groups, Colors.blue, onTap: () {
                      setState(() => _activeSection = 'Student Management');
                    }),
                    _infoCard("Total Rooms", totalRooms.toString(),
                        Icons.meeting_room, Colors.teal),
                    _infoCard("Occupied Rooms", occupiedRooms.toString(),
                        Icons.bed, Colors.teal),
                    _infoCard("Vacant Rooms", vacantRooms.toString(),
                        Icons.single_bed, Colors.red),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('leaves')
                          .where('status', isEqualTo: 'Pending')
                          .snapshots(),
                      builder: (context, leaveSnap) {
                        String count = leaveSnap.hasData
                            ? leaveSnap.data!.docs.length.toString()
                            : "0";
                        return _infoCard("Pending Leave", count,
                            Icons.mail_outline, Colors.orange, onTap: () {
                          setState(() => _activeSection = 'Leave Requests');
                        });
                      },
                    ),
                    _infoCard("Pending Fees", "₹1800",
                        Icons.account_balance_wallet, Colors.brown),
                  ],
                ),
                const SizedBox(height: 25),
                _buildDashboardSection(
                  "Public Chat & Notice Management",
                  _buildChatControlPanel(),
                  onViewAll: () =>
                      setState(() => _activeSection = 'Hostel Chat'),
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child: _buildDashboardSection(
                          "Attendance Status",
                          _buildAttendanceModule(),
                          onViewAll: () => setState(
                              () => _activeSection = 'Attendance Override'),
                        )),
                    const SizedBox(width: 25),
                    Expanded(
                        flex: 3,
                        child: _buildDashboardSection(
                          "Notice Board Feed",
                          _buildLiveNoticeList(),
                          onViewAll: () => _showAddNoticeDialog(context),
                        )),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: _buildDashboardSection(
                          "Recent Leave Requests",
                          _buildLiveLeaveTable(),
                          onViewAll: () =>
                              setState(() => _activeSection = 'Leave Requests'),
                        )),
                    const SizedBox(width: 25),
                    Expanded(
                        flex: 2,
                        child: _buildDashboardSection(
                            "Recent Complaints", _buildMiniComplaintFeed())),
                  ],
                ),
                const SizedBox(height: 25),
                _buildDashboardSection("Hostel Layout", _buildLayoutModule()),
                const SizedBox(height: 30),
              ],
            ),
          );
        });
  }

  Widget _buildMiniComplaintFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('timestamp', descending: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Padding(
              padding: EdgeInsets.all(10),
              child: Text("No active complaints."));

        return Column(
          children: docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            DateTime? ts = (data['timestamp'] as Timestamp?)?.toDate();
            String timeStr =
                ts != null ? DateFormat('jm').format(ts) : "Just now";

            return _complaintMiniItem(data['studentName'] ?? "Anonymous",
                data['roomNo'] ?? "--", timeStr);
          }).toList(),
        );
      },
    );
  }

  Widget _complaintMiniItem(String name, String room, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 18, color: Colors.red)),
          const SizedBox(width: 15),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text("Room $room • $time",
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceModule() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          double percentage = 0.0;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            int total = snapshot.data!.docs.length;
            int present = snapshot.data!.docs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['status'] == 'Active')
                .length;
            percentage = (present / total) * 100;
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(width: 10),
                  const Text("Active\nToday",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              const Text("Manual override for GPS issues?",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _activeSection = 'Attendance Override'),
                  icon: const Icon(Icons.fact_check_outlined,
                      size: 18, color: Colors.white),
                  label: const Text("MANUAL OVERRIDE",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          );
        });
  }

  void _showAddNoticeDialog(BuildContext context) {
    final TextEditingController _noticeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF438A7F).withOpacity(0.1),
              child: const Icon(Icons.campaign, color: Color(0xFF438A7F)),
            ),
            const SizedBox(width: 15),
            const Text("Broadcast Official Notice",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "This notice will appear on all student dashboards and in the Official Notice chat room.",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              TextField(
                controller: _noticeController,
                decoration: InputDecoration(
                  hintText: "Type important instructions here...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Discard", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF438A7F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            ),
            onPressed: () async {
              String text = _noticeController.text.trim();
              if (text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notices').add({
                  'title': text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'author': 'Warden Office',
                });

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc('notice_channel')
                    .collection('messages')
                    .add({
                  'senderId': 'STAFF',
                  'senderName': 'WARDEN OFFICE',
                  'senderRole': 'Warden',
                  'messageText': text,
                  'type': 'text',
                  'timestamp': FieldValue.serverTimestamp(),
                  'isDeleted': false,
                  'isPinned': true,
                });

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc('notice_channel')
                    .update({
                  'lastMessage': text,
                  'lastTimestamp': FieldValue.serverTimestamp(),
                  'lastSender': 'Warden',
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Broadcast sent successfully!"),
                        backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text("Publish Broadcast",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String val, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Column(
            children: [
              CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  radius: 22,
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(height: 12),
              Text(val,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatControlPanel() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc('hostel_public')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        bool isLocked = data['isLocked'] ?? false;
        String pinned = data['pinnedText'] ?? "No active announcement";

        return Row(
          children: [
            Expanded(
              child: _buildControlTile(
                title: "Public Chat Status",
                subtitle: isLocked
                    ? "LOCKED (Students cannot type)"
                    : "OPEN (All students can type)",
                icon: isLocked ? Icons.lock : Icons.lock_open,
                iconColor: isLocked ? Colors.red : Colors.green,
                trailing: Switch(
                  value: !isLocked,
                  activeColor: Colors.green,
                  onChanged: (val) =>
                      _chatControlService.toggleChatLock('hostel_public', !val),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildControlTile(
                title: "Pinned Announcement",
                subtitle: pinned,
                icon: Icons.push_pin,
                iconColor: Colors.orange,
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showPinDialog(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A237E))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context) {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Pinned Message"),
        content: TextField(
            controller: pinController,
            decoration: const InputDecoration(
                hintText: "Enter new announcement text...")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _chatControlService.pinMessage(
                  'hostel_public', 'manual_pin', pinController.text);
              Navigator.pop(context);
            },
            child: const Text("Pin Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNoticeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("No recent notices.");
        return Column(
          children: docs.map((d) {
            Timestamp? t = d['timestamp'] as Timestamp?;
            String dateStr =
                t != null ? DateFormat('hh:mm').format(t.toDate()) : "--:--";
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.notifications_active,
                    color: Colors.orange, size: 18),
                title: Text(d['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                trailing: Text(dateStr,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLiveLeaveTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leaves')
          .where('status', isEqualTo: 'Pending')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: LinearProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No pending leaves."));
        return DataTable(
          headingRowHeight: 40,
          horizontalMargin: 0,
          columns: const [
            DataColumn(
                label: Text("Name",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("Room",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text("To", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text("Action",
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _leaveRow(data['studentName'] ?? "---",
                data['roomNo'] ?? "---", data['endDate'] ?? "---", doc.id);
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
          onPressed: () => FirebaseFirestore.instance
              .collection('leaves')
              .doc(docId)
              .update({'status': 'Approved'}),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text("Approve",
              style: TextStyle(color: Colors.white, fontSize: 11)))),
    ]);
  }

  Widget _buildLayoutModule() {
    return Column(
      children: [
        const Icon(Icons.map_outlined, size: 40, color: Colors.blueGrey),
        const SizedBox(height: 10),
        const Text("Hostel occupancy management",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 15),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue),
                child: const Text("View Layout",
                    style: TextStyle(color: Colors.white)))),
      ],
    );
  }

  Widget _buildDashboardSection(String title, Widget content,
      {VoidCallback? onViewAll}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E))),
              InkWell(
                onTap: onViewAll,
                child: Text(
                    onViewAll == null
                        ? ""
                        : (title.contains("Notice")
                            ? "+ Add New"
                            : "View All >"),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 30),
          content,
        ],
      ),
    );
  }

  Widget _buildScrollableSidebar() {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: ListView(
        children: [
          _sidebarTitle(" Important Links"),
          _sidebarItem("Dashboard", Icons.grid_view_outlined),
          _sidebarItem("Profile Overview", Icons.person_outline),
          _sidebarItem("Merit Setup View", Icons.visibility_outlined),
          _sidebarItem("Complaint Box", Icons.mail_outline),
          _sidebarTitle(" Communication"),
          _sidebarItem("Hostel Chat", Icons.chat_bubble_outline),
          _sidebarTitle(" Leave & Attendance"),
          _sidebarItem("Leave Requests", Icons.time_to_leave_outlined),
          _sidebarItem("Attendance Override", Icons.fact_check_outlined),
          _sidebarItem("Attendance Reports", Icons.analytics_outlined),
          _sidebarTitle(" Services"), // NEW SECTION
          _sidebarItem("Mess Menu", Icons.restaurant_menu_outlined), // NEW ITEM
          _sidebarTitle(" Student Management"),
          _sidebarItem("Student Management", Icons.person_search_outlined),
          _sidebarItem("Student Admission", Icons.person_add_outlined),
          _sidebarItem("Room Allocation", Icons.bed_outlined),
        ],
      ),
    );
  }

  Widget _sidebarTitle(String title) {
    return Container(
        padding: const EdgeInsets.all(15),
        color: AppColors.primaryBlue,
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)));
  }

  Widget _sidebarItem(String text, IconData icon) {
    bool isSelected = _activeSection == text;
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: isSelected ? Colors.white : AppColors.primaryBlue, size: 20),
      title: Text(text,
          style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold)),
      tileColor: isSelected ? AppColors.primaryBlue : Colors.transparent,
      onTap: () => setState(() => _activeSection = text),
    );
  }
}
