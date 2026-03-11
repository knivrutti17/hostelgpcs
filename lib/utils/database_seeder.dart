import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static Future<void> uploadStudents() async {
    try {
      // 1. UPDATED FILE NAME: Load new student_data.json
      final String response = await rootBundle.loadString('assets/student_data.json');
      final List<dynamic> data = json.decode(response);
      print("TOTAL JSON ENTRIES FOUND: ${data.length}");

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int skipCount = 0;

      for (var student in data) {
        // 2. Updated key to match your new schema: 'rollNo' instead of 'roll_no'
        String rollId = student['rollNo']?.toString() ?? "";
        if (rollId.isEmpty) continue;

        // 3. CHECK FOR DUPLICATES: Only add if student doesn't exist
        var existingDoc = await firestore.collection('users').doc(rollId).get();

        if (!existingDoc.exists) {
          // 4. Map JSON keys to match your exact Firestore fields
          await firestore.collection('users').doc(rollId).set({
            'name': student['name'] ?? "Unknown",
            'year': student['year'] ?? "N/A",
            'rollNo': rollId,
            'roomNo': student['roomNo']?.toString() ?? "N/A", // Matches "311" string format
            'department': student['department'] ?? "N/A",
            'contact': student['mobile']?.toString() ?? "N/A", // Maps mobile to contact
            'parentMobile': student['parentMobile']?.toString() ?? "N/A",
            'email': student['email'] ?? "N/A",
            'category': student['category'] ?? "N/A",
            'address': student['address'] ?? "N/A",
            'hostel': student['hostelName'] ?? "N/A",
            'bloodGroup': student['bloodGroup'] ?? "N/A",
            'dob': student['dob'] ?? "N/A",
            'role': 'student', // Required for Security Rules
            'status': 'Active',
            'uid': rollId,
            'feesPaid': (student['fees'] != null && student['fees'] >= 1800),
            'timestamp': student['timestamp'] ?? "",
          });
          successCount++;
        } else {
          // Skip if student (like Viraj or Aniket) is already in database
          skipCount++;
        }
      }
      print("SUCCESS: ADDED $successCount NEW STUDENTS. SKIPPED $skipCount DUPLICATES.");
    } catch (e) {
      print("CRITICAL ERROR: $e");
    }
  }
}