import 'dart:io';
import 'dart:convert'; // Required for Base64 image decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

// Internal screen imports
import 'package:gpcs_hostel_portal/screens/mobile/student_profile.dart';
import 'package:gpcs_hostel_portal/screens/mobile/complain.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/screens/mobile/request_leave.dart';
import 'package:gpcs_hostel_portal/screens/mobile/attendance_history.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_fees.dart';
import 'package:gpcs_hostel_portal/screens/mobile/mess_menu_page.dart';
import 'package:gpcs_hostel_portal/screens/mobile/emergency_contacts_page.dart'; // IMPORT EMERGENCY PAGE

// Import the new Services and Chat Screens
import 'package:gpcs_hostel_portal/services/download_service.dart';
import 'package:gpcs_hostel_portal/screens/mobile/chat/chat_list_screen.dart';
import 'package:gpcs_hostel_portal/screens/mobile/documents_screen.dart';
import 'package:gpcs_hostel_portal/services/chat_service.dart'; // REQUIRED FOR INITIALIZATION

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const StudentProfile(),
    const RequestLeave(),
    const StudentFees(),
    const RegisterComplaint(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // CRITICAL: Prevents Overflow
        backgroundColor: const Color(0xFFF8F9FB),
        body: IndexedStack(index: _currentIndex, children: _pages),

        // PROFESSIONAL CENTRAL FAB
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildUniqueSpeedDial(context),

        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildUniqueSpeedDial(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 12,
      spaceBetweenChildren: 8,
      backgroundColor: const Color(0xFF438A7F),
      foregroundColor: Colors.white,
      elevation: 10,
      animationCurve: Curves.easeInOut,
      shape: const CircleBorder(),

      // --- REQUIREMENT: Single Tap (+) -> Open Hostel Chat System directly ---
      onPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      },

      // QUICK DOWNLOAD ACTIONS (FUNCTIONAL)
      children: [
        SpeedDialChild(
          child: const Icon(Icons.receipt_long, color: Colors.white),
          backgroundColor: Colors.green.shade600,
          label: 'Fee Receipt',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => DownloadService.handleGlobalDownload(context, 'Fee Receipt'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.badge, color: Colors.white),
          backgroundColor: Colors.blue.shade600,
          label: 'My ID Card',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => DownloadService.handleGlobalDownload(context, 'ID Card'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.description, color: Colors.white),
          backgroundColor: Colors.orange.shade600,
          label: 'Leave Report',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => DownloadService.handleGlobalDownload(context, 'Leave Report'),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), // FIXED OVERFLOW
      notchMargin: 8.0,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.grid_view_rounded, 0, 'Home'),
            _navIcon(Icons.person_rounded, 1, 'Profile'),
            const SizedBox(width: 45), // SPACE FOR FAB
            _navIcon(Icons.exit_to_app_rounded, 2, 'Leave'),
            _navIcon(Icons.receipt_long_rounded, 4, 'Requests'),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF438A7F) : Colors.grey, size: 24),
          Text(label, style: TextStyle(
              color: isSelected ? const Color(0xFF438A7F) : Colors.grey,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
          ),
        ],
      ),
    );
  }
}

class ProfessionalCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const ProfessionalCard({super.key, required this.child, this.onTap});

  @override
  State<ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<ProfessionalCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isPressed ? Colors.transparent : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  Future<String?> _getRollNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_roll');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
        future: _getRollNo(),
        builder: (context, rollSnapshot) {
          if (rollSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final String? rollNo = rollSnapshot.data;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(rollNo).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Profile data not found", style: TextStyle(color: Colors.grey)));
              }

              var data = snapshot.data!.data() as Map<String, dynamic>;

              // --- REQUIREMENT: AUTOMATIC CHAT INITIALIZATION ---
              String roomNo = data['roomNo'] ?? "Unknown";
              ChatService().initializeHostelChats(roomNo);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(data['name'] ?? "Student"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Column(
                        children: [
                          // --- UPDATED: Pass photoUrl for Profile Image ---
                          _buildHostelIDCard(
                            data['name'] ?? "Student",
                            data['rollNo'] ?? "N/A",
                            data['roomNo'] ?? "N/A",
                            data['photoUrl'],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: ProfessionalCard(child: _infoItem("ADMISSION", data['status'] ?? "Pending", Colors.orange))),
                              const SizedBox(width: 15),
                              Expanded(child: ProfessionalCard(
                                onTap: () => Navigator.pushNamed(context, '/room_details_screen'),
                                child: _roomDetailsItem(data['roomNo'] ?? "N/A"),
                              )),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- UPDATED: Navigation to Announcement Center ---
                              Expanded(
                                child: ProfessionalCard(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AnnouncementCenter())
                                  ),
                                  child: Hero(tag: 'updates_expand', child: _buildAnnouncements()),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // --- UPDATED: Navigation to Mess Menu Page ---
                              Expanded(
                                child: ProfessionalCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MessMenuPage()),
                                    );
                                  },
                                  child: _buildMealSchedule(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildLiveAttendanceSection(context, rollNo ?? ""),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              // --- UPDATED EMERGENCY TAB: WORKING ---
                              Expanded(
                                child: ProfessionalCard(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const EmergencyContactsPage()),
                                    );
                                  },
                                  child: _buildEmergencyCard(),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(child: ProfessionalCard(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceHistory()));
                                },
                                child: _buildHistoryCard(),
                              )),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildLiveAttendanceSection(BuildContext context, String rollNo) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_attendance')
          .where('studentUid', isEqualTo: rollNo)
          .where('date', isEqualTo: today)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
        }

        bool isAnyPresent = snapshot.hasData &&
            snapshot.data!.docs.any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Present';
            });

        bool morningDone = snapshot.hasData &&
            snapshot.data!.docs.any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String slotValue = data.containsKey('slot') ? data['slot'] : 'Manual';
              return slotValue == 'Morning' || slotValue == 'Manual';
            });

        bool nightDone = snapshot.hasData &&
            snapshot.data!.docs.any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String slotValue = data.containsKey('slot') ? data['slot'] : 'Manual';
              return slotValue == 'Night' || slotValue == 'Manual';
            });

        return ProfessionalCard(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ATTENDANCE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF438A7F))),
                    if (isAnyPresent)
                      const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(isAnyPresent ? Icons.check_circle : Icons.error_outline,
                        color: isAnyPresent ? Colors.green : Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAnyPresent ? "Attendance Marked" : "Not Marked",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text("Morning: 10AM-4PM | Night: 8PM-9PM",
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _slotChip("MORNING", morningDone),
                    const SizedBox(width: 10),
                    _slotChip("NIGHT", nightDone),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (morningDone && nightDone) ? null : () => Navigator.pushNamed(context, '/attendance_page'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (morningDone && nightDone) ? Colors.grey[200] : const Color(0xFF438A7F),
                      foregroundColor: (morningDone && nightDone) ? Colors.grey[500] : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text((morningDone && nightDone) ? "FULLY PRESENT" : "MARK ATTENDANCE",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slotChip(String label, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDone ? Colors.green : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDone ? Icons.check : Icons.access_time, size: 12, color: isDone ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFA1E7D1), Color(0xFF438A7F)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HOSTEL HUB", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
          Text("Welcome back, $name", style: const TextStyle(fontSize: 15, color: Colors.white70)),
        ],
      ),
    );
  }

  // --- UPDATED: Renders Profile Image from photoUrl Base64 ---
  Widget _buildHostelIDCard(String name, String roll, String room, String? photoUrl) {
    return ProfessionalCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF438A7F), width: 2)),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFFA1E7D1),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? MemoryImage(base64Decode(photoUrl))
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: const Color(0xFF438A7F))
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Enroll: $roll", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFA1E7D1).withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                    child: Text("ROOM $room", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF438A7F))),
                  ),
                ],
              ),
            ),
            const Icon(Icons.qr_code_2_rounded, size: 40, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _roomDetailsItem(String room) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ROOM DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF438A7F))),
          const SizedBox(height: 8),
          Text(room, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("View Partners", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: c)),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("Status Active", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("EMERGENCY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.redAccent)),
          SizedBox(height: 10),
          Text("Warden: +91 98765...", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text("Guard: +91 88223...", style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HISTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          SizedBox(height: 10),
          Text("Calendar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("View Logs", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Listen to Real-time Notices ---
  Widget _buildAnnouncements() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notices').orderBy('timestamp', descending: true).limit(2).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("UPDATES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                const SizedBox(height: 10),
                if (docs.isEmpty)
                  const Text("No recent updates", style: TextStyle(fontSize: 10, color: Colors.grey))
                else
                  ...docs.map((d) => _annoRow(Icons.campaign_rounded, d['title'] ?? "")).toList(),
              ],
            ),
          );
        }
    );
  }

  Widget _annoRow(IconData i, String t) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(i, size: 14, color: const Color(0xFF438A7F)), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))]));
  }

  Widget _buildMealSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFA1E7D1).withOpacity(0.3), borderRadius: BorderRadius.circular(24)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MEALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF438A7F))),
          SizedBox(height: 8),
          Text("B: 7:30 AM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text("D: 8:00PM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- NEW CLASS: FULL SCREEN ANNOUNCEMENT CENTER ---
class AnnouncementCenter extends StatelessWidget {
  const AnnouncementCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Announcement Center", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF438A7F), fontSize: 18)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notices').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No notices posted yet."));
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var d = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF1F8F7), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Color(0xFF438A7F), size: 28),
                    const SizedBox(width: 15),
                    Expanded(child: Text(d['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}