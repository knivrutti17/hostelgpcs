import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_profile.dart';
import 'package:gpcs_hostel_portal/screens/mobile/complain.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
// NEW: Import the leave request screen
import 'package:gpcs_hostel_portal/screens/mobile/request_leave.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  // UPDATED: Added RequestLeave() to the pages list
  final List<Widget> _pages = [
    const HomeContent(),
    const StudentProfile(),
    const RequestLeave(), // NEW: Leave Request Page added here
    const Center(child: Text("Fees")),
    const RegisterComplaint()
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppStyle.primaryTeal,
      unselectedItemColor: AppStyle.textGrey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 20,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        // NEW: Leave Item added to the bottom bar
        BottomNavigationBarItem(icon: Icon(Icons.exit_to_app_rounded), label: 'Leave'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Fees'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Requests'),
      ],
    );
  }
}

// --- PROFESSIONAL REACTIVE COMPONENT ---
// (Logic preserved as per your original file)
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(data['name'] ?? "Student"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Column(
                  children: [
                    _buildHostelIDCard(data['name'] ?? "Rohit Kakde", data['rollNo'] ?? "3434", data['roomNo'] ?? "A-102"),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: ProfessionalCard(child: _infoItem("ADMISSION", data['status'] ?? "Pending", Colors.orange))),
                        const SizedBox(width: 15),
                        Expanded(child: ProfessionalCard(
                          onTap: () => Navigator.pushNamed(context, '/room_details_screen'),
                          child: _roomDetailsItem(data['roomNo'] ?? "A-102"),
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: ProfessionalCard(child: _buildAnnouncements())),
                        const SizedBox(width: 15),
                        Expanded(child: ProfessionalCard(child: _buildMealSchedule())),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: ProfessionalCard(child: _buildEmergencyCard())),
                        const SizedBox(width: 15),
                        // Preserved Leave Info card on Home
                        Expanded(child: ProfessionalCard(child: _buildLeaveCard())),
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

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 25),
      decoration: const BoxDecoration(
        gradient: AppStyle.headerGradient,
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

  Widget _buildHostelIDCard(String name, String roll, String room) {
    return ProfessionalCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppStyle.primaryTeal, width: 2)),
              child: CircleAvatar(radius: 35, backgroundColor: AppStyle.accentTeal, child: const Icon(Icons.person, size: 40, color: AppStyle.primaryTeal)),
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
                    decoration: BoxDecoration(color: AppStyle.accentTeal.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                    child: Text("ROOM $room", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppStyle.primaryTeal)),
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
          const Text("ROOM DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppStyle.primaryTeal)),
          const SizedBox(height: 8),
          Text(room, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Suraj Patil", style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  Widget _buildLeaveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("LEAVE INFO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          SizedBox(height: 10),
          Text("3 Days", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("Balance Left", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("UPDATES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          _annoRow(Icons.campaign_rounded, "New Menu Out"),
          _annoRow(Icons.event_note_rounded, "Yoga session"),
        ],
      ),
    );
  }

  Widget _annoRow(IconData i, String t) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(i, size: 14, color: AppStyle.primaryTeal), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 10))]));
  }

  Widget _buildMealSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppStyle.accentTeal.withOpacity(0.3), borderRadius: BorderRadius.circular(24)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MEALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppStyle.primaryTeal)),
          SizedBox(height: 8),
          Text("B: 7:30 AM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text("D: 8:00 PM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}