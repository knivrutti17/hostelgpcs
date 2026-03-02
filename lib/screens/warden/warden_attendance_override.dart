import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WardenAttendanceOverride extends StatefulWidget {
  const WardenAttendanceOverride({super.key});

  @override
  State<WardenAttendanceOverride> createState() => _WardenAttendanceOverrideState();
}

class _WardenAttendanceOverrideState extends State<WardenAttendanceOverride> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual Attendance Mark"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Step 1: Bind Student List
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No students available."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var student = snapshot.data!.docs[index];
              var data = student.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(data['name'] ?? "Unknown Student"),
                  subtitle: Text("Room: ${data['roomNo'] ?? 'N/A'}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () => _markAttendanceManually(student.id, data['name']),
                    child: const Text("Mark Present", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Step 2: UPDATED Manual Write Logic
  void _markAttendanceManually(String studentId, String studentName) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await FirebaseFirestore.instance
          .collection('daily_attendance')
          .doc("${today}_$studentId")
          .set({
        'studentUid': studentId,
        'studentName': studentName,
        'status': 'Present',
        'slot': 'Manual', // CRITICAL FIX: Adding the missing slot field
        'markedBy': 'warden',
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Attendance marked for $studentName"))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }
}