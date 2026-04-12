import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WardenAttendanceOverride extends StatefulWidget {
  const WardenAttendanceOverride({super.key});

  @override
  State<WardenAttendanceOverride> createState() =>
      _WardenAttendanceOverrideState();
}

class _WardenAttendanceOverrideState extends State<WardenAttendanceOverride> {
  // Step A: Define the Search Controller and Query String
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual Attendance Mark"),
        backgroundColor: const Color(0xFF0077C2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Step B: Add the Search Bar UI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by Name or Roll No...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0077C2)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                // Step C: Update the Filtering Logic
                final allStudents = snapshot.data!.docs;
                final filteredStudents = allStudents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? "").toString().toLowerCase();
                  final rollNo =
                      (data['rollNo'] ?? "").toString().toLowerCase();

                  // Filter matches if search query is found in name OR roll number
                  return name.contains(_searchQuery) ||
                      rollNo.contains(_searchQuery);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(
                      child: Text("No matching students found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    var student = filteredStudents[index];
                    var data = student.data() as Map<String, dynamic>;
                    String? base64String = data['photoUrl'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF0077C2),
                          backgroundImage:
                              (base64String != null && base64String.isNotEmpty)
                                  ? MemoryImage(base64Decode(base64String))
                                  : null,
                          child: (base64String == null || base64String.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(data['name'] ?? "Unknown Student",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Roll No: ${data['rollNo'] ?? 'N/A'}"),
                            Text("Room: ${data['roomNo'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          onPressed: () =>
                              _markAttendanceManually(student.id, data['name']),
                          child: const Text("Mark Present",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
        'slot': 'Manual',
        'markedBy': 'warden',
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Attendance marked for $studentName"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}
