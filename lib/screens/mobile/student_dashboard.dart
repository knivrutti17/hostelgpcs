import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gpcs_hostel_portal/screens/mobile/student_profile.dart';
import 'package:gpcs_hostel_portal/screens/mobile/complain.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart'; // Import Styles

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
    const Center(child: Text("Fees")),
    const RegisterComplaint()
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppStyle.bgLightGrey, // Use theme background
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppStyle.primaryTeal, // Themed selection
          unselectedItemColor: AppStyle.textGrey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Fees'),
            BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Requests'),
          ],
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
          child: Column(
            children: [
              _buildHeader(data['name'] ?? "kakde"),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRoomCard(data['roomNo'] ?? '---', data['rollNo'] ?? '3434'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _statusItem("ADMISSION", data['status'] ?? "Pending", AppStyle.statusOrange)),
                        const SizedBox(width: 10),
                        Expanded(child: _statusItem("FEES", "View Details", Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAnnouncements()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMealSchedule()),
                      ],
                    ),
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
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
      decoration: const BoxDecoration(
        gradient: AppStyle.headerGradient, // Themed gradient
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HOSTEL HUB", style: AppStyle.headingStyle), // Themed text
          Text("Welcome, $name", style: AppStyle.subtitleStyle), // Themed text
        ],
      ),
    );
  }

  Widget _buildRoomCard(String room, String roll) {
    return Container(
      decoration: AppStyle.cardDecoration, // Themed card style
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: AppStyle.accentTeal,
            child: const Icon(Icons.person, color: AppStyle.primaryTeal)
        ),
        title: Text("ROOM $room", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Enroll: $roll"),
      ),
    );
  }

  Widget _statusItem(String l, String v, Color c) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: AppStyle.bgWhite,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: c.withOpacity(0.1))
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
          ]
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.cardDecoration, // Themed container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DAILY ANNOUNCEMENTS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppStyle.textGrey)),
          const SizedBox(height: 8),
          _annText("Mess menu updated", Icons.restaurant_menu),
          _annText("Yoga session @ 6 AM", Icons.check_circle_outline),
          _annText("Submit leave requests", Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _annText(String t, IconData i) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
          children: [
            Icon(i, size: 12, color: AppStyle.secondaryTeal), // Themed icon
            const SizedBox(width: 5),
            Text(t, style: const TextStyle(fontSize: 10))
          ]
      )
  );

  Widget _buildMealSchedule() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppStyle.accentTeal, // Themed background
          borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MEAL SCHEDULE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppStyle.primaryTeal)),
          const SizedBox(height: 8),
          const Text("BREAKFAST: 7.30 - 8.00 AM", style: TextStyle(fontSize: 8)),
          const Text("DINNER: 7.00 - 9.00 PM", style: TextStyle(fontSize: 8)),
          const SizedBox(height: 10),
          const Text("TODAY: ALLO PARATHA, DAL MAKHANI", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }
}