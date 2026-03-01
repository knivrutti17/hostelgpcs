import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isLoading = false;

  Future<void> _markAttendance() async {
    setState(() => _isLoading = true);
    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "Location permissions are denied.";
      }

      // 2. Get Config & Current Position
      var config = await FirebaseFirestore.instance.collection('attendance_config').doc('settings').get();
      if (!config.exists) throw "Attendance configuration not found.";

      Position pos = await Geolocator.getCurrentPosition();

      // 3. Distance Check
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          config['latitude'],
          config['longitude']
      );

      if (distance > config['radius']) {
        throw "Outside premises: ${distance.toInt()}m away.";
      }

      // 4. Save to daily_attendance using .add()
      DateTime now = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(now);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw "User not logged in.";

      // UPDATED: Using .add() instead of .doc().set() to bypass permission issues
      await FirebaseFirestore.instance.collection('daily_attendance').add({
        'studentUid': user.uid,
        'status': 'Present',
        'markedBy': 'student',
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Marked Present!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Attendance"),
        backgroundColor: const Color(0xFF00897B),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 100, color: Color(0xFF00897B)),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("MARK ATTENDANCE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}