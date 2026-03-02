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

  // NEW: Helper function to convert DB time strings (e.g. "10:30") to comparable values
  bool _isWithinTimeRange(String startStr, String endStr, DateTime now) {
    try {
      final DateFormat format = DateFormat("H:m");
      DateTime start = format.parse(startStr);
      DateTime end = format.parse(endStr);

      // Create comparable DateTime objects for today
      DateTime startToday = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      DateTime endToday = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      return now.isAfter(startToday) && now.isBefore(endToday);
    } catch (e) {
      return false;
    }
  }

  Future<void> _markAttendance() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in.";

      // 1. Fetch Configuration (Crucial for Permission Check)
      var config = await FirebaseFirestore.instance.collection('attendance_config').doc('settings').get();
      if (!config.exists) throw "Attendance configuration not found.";

      // 2. Exact match for your Database fields
      bool isAnytimeAllowed = config.data()?['allowAnytime'] ?? false;
      double targetLat = (config.data()?['latitude'] ?? 0.0).toDouble();
      double targetLng = (config.data()?['longitude'] ?? 0.0).toDouble();
      double targetRadius = (config.data()?['radius'] ?? 1000).toDouble();

      // 3. UPDATED: Dynamic Time Slot Logic
      DateTime now = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(now);
      String slot = "";

      if (isAnytimeAllowed) {
        slot = "Manual";
      } else {
        // Fetch dynamic strings from DB
        String morningS = config.data()?['morning_start'] ?? "10:0";
        String morningE = config.data()?['morning_end'] ?? "16:0";
        String nightS = config.data()?['night_start'] ?? "20:0";
        String nightE = config.data()?['night_end'] ?? "21:0";

        if (_isWithinTimeRange(morningS, morningE, now)) {
          slot = "Morning";
        } else if (_isWithinTimeRange(nightS, nightE, now)) {
          slot = "Night";
        } else {
          throw "Attendance is closed. Windows: $morningS-$morningE or $nightS-$nightE";
        }
      }

      // 4. Check for Duplicates
      var existingRecord = await FirebaseFirestore.instance
          .collection('daily_attendance')
          .where('studentUid', isEqualTo: user.uid)
          .where('date', isEqualTo: today)
          .where('slot', isEqualTo: slot)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        throw "You already marked $slot attendance for today.";
      }

      // 5. Permission and Location
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "Location permissions are denied.";
      }

      Position pos = await Geolocator.getCurrentPosition();

      // 6. Distance Check using DB Coordinates
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          targetLat,
          targetLng
      );

      if (distance > targetRadius) {
        throw "Outside premises: ${distance.toInt()}m away.";
      }

      // 7. Save Record
      await FirebaseFirestore.instance.collection('daily_attendance').add({
        'studentUid': user.uid,
        'status': 'Present',
        'slot': slot,
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$slot Attendance Marked Present!")));
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
        iconTheme: const IconThemeData(color: Colors.white),
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
                height: 55,
                child: ElevatedButton(
                  onPressed: _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("MARK ATTENDANCE NOW",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}