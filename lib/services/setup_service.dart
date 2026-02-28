import 'package:cloud_firestore/cloud_firestore.dart';

class HostelSetupService {
  static Future<void> runAutoSetup() async {
    final firestore = FirebaseFirestore.instance;

    // Helper to build the branch data
    Map<String, dynamic> branchData() {
      return {
        'total_seats': 30,
        'quota': {
          'open': 10,
          'sc': 10,
          'st': 5,
          'obc': 5,
        }
      };
    }

    // Helper to build the floor/year structure
    Map<String, dynamic> yearStructure() {
      return {
        'capacity': 90,
        'branches': {
          'IT': branchData(),
          'Mechanical': branchData(),
          'Civil': branchData(),
        }
      };
    }

    try {
      // 🔹 Automatic Setup for Devgiri Boy Hostel
      await firestore.collection('hostels').doc('Devgiri_boy').set({
        '1st_year': yearStructure(),
        '2nd_year': yearStructure(),
        '3rd_year': yearStructure(),
        'setup_date': FieldValue.serverTimestamp(),
      });

      // 🔹 Automatic Setup for Shivneri Hostel
      await firestore.collection('hostels').doc('Shivneri').set({
        '1st_year': yearStructure(),
        '2nd_year': yearStructure(),
        '3rd_year': yearStructure(),
        'setup_date': FieldValue.serverTimestamp(),
      });

      print("Hostel Database Setup Successful!");
    } catch (e) {
      print("Database Setup Failed: $e");
    }
  }
}