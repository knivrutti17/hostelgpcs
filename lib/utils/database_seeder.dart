import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static Future<void> uploadStudents() async {
    try {
      // 1. Load JSON array
      final String response = await rootBundle.loadString('assets/student.json');
      final List<dynamic> data = json.decode(response);
      print("TOTAL JSON ENTRIES FOUND: ${data.length}");

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      int successCount = 0;

      for (var student in data) {
        String rollId = student['roll_no']?.toString() ?? "";
        if (rollId.isEmpty) continue;

        // 2. Map JSON keys to your LIVE Firestore fields
        await firestore.collection('users').doc(rollId).set({
          'name': student['name'] ?? "Unknown",
          'year': student['year'] ?? "N/A",
          'rollNo': rollId,
          'roomNo': student['room'] ?? "N/A",
          'branch': student['dept'] ?? "IT", // Maps 'dept' to 'branch'
          'contact': student['mobile'] ?? "N/A", // Maps 'mobile' to 'contact'
          'parentMobile': student['parent_mob'] ?? "N/A",
          'email': student['email'] ?? "N/A",
          'category': student['category'] ?? "N/A",
          'address': student['address'] ?? "N/A",
          'hostel': student['hostel'] ?? "N/A",
          'bloodGroup': student['blood'] ?? "N/A",
          'dob': student['dob'] ?? "N/A",
          'role': 'student', // Required for your Security Rules
          'status': 'Active',
          'uid': rollId,
          'feesPaid': (student['fees'] != null && student['fees'] >= 1800),
        }, SetOptions(merge: true));

        successCount++;
      }
      print("SUCCESSFULLY ADDED $successCount STUDENTS TO 'USERS' COLLECTION.");
    } catch (e) {
      print("CRITICAL ERROR: $e");
    }
  }
}