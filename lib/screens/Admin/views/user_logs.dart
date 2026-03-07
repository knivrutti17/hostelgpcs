import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../styles.dart';

class UserLogsView extends StatefulWidget {
  const UserLogsView({super.key});

  @override
  State<UserLogsView> createState() => _UserLogsViewState();
}

class _UserLogsViewState extends State<UserLogsView> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight - 150,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER WITH SYSTEM LOGGING STATUS
          _buildCreativeHeader(),
          const SizedBox(height: 30),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activity_logs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyLogs();
                }

                // Sorting logs by most recent timestamp
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (t1 == null || t2 == null) return 0;
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isLast = index == docs.length - 1;

                    return _buildTimelineItem(data, isLast);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Administrative Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              Text("Tracking secure access events", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          _buildLoggingSwitch(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> data, bool isLast) {
    DateTime logDate = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();

    // UPDATED: Primary text is now the ROLE (ADMIN, WARDEN, HOD)
    String userRole = (data['role']?.toString() ?? "USER").toUpperCase();
    String userEmail = data['email'] ?? 'Unknown Account';

    Color roleColor = _getRoleColor(userRole);

    return IntrinsicHeight(
      child: Row(
        children: [
          // TIMELINE LINE AND ROLE-BASED DOT
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: roleColor.withOpacity(0.4), blurRadius: 4)]),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(width: 20),
          // LOG CONTENT CARD
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_getRoleIcon(userRole), color: roleColor, size: 20),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UPDATED: Title shows Role instead of "User Login"
                        Text("$userRole ACCESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: roleColor)),
                        const SizedBox(height: 4),
                        Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MMM dd').format(logDate), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('hh:mm a').format(logDate), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Role-based Colors for high scannability
  Color _getRoleColor(String role) {
    if (role.contains("ADMIN")) return Colors.deepPurple;
    if (role.contains("WARDEN")) return Colors.indigo;
    if (role.contains("HOD")) return Colors.teal;
    return Colors.blueGrey;
  }

  // UPDATED: Role-based Icons
  IconData _getRoleIcon(String role) {
    if (role.contains("ADMIN")) return Icons.admin_panel_settings;
    if (role.contains("WARDEN")) return Icons.security;
    if (role.contains("HOD")) return Icons.supervised_user_circle;
    return Icons.person;
  }

  Widget _buildEmptyLogs() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          const Text("No Recent Activity Found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoggingSwitch() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system_settings').doc('logging_config').snapshots(),
      builder: (context, snapshot) {
        bool isLogging = snapshot.hasData && snapshot.data!.exists ? snapshot.data!.get('isLoggingEnabled') ?? false : false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: isLogging ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(30)),
          child: Row(
            children: [
              Text(isLogging ? "ACTIVE" : "PAUSED", style: TextStyle(color: isLogging ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
              const SizedBox(width: 4),
              Switch(
                value: isLogging,
                activeColor: Colors.green,
                onChanged: (val) async {
                  await FirebaseFirestore.instance.collection('system_settings').doc('logging_config').set({'isLoggingEnabled': val}, SetOptions(merge: true));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}