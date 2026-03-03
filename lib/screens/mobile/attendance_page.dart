import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isLoading = false;

  // Helper to convert DB strings to comparable values
  bool _isWithinTimeRange(String startStr, String endStr, DateTime now) {
    try {
      final DateFormat format = DateFormat("H:m");
      DateTime start = format.parse(startStr);
      DateTime end = format.parse(endStr);

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
      // 1. UPDATED: Fetch Roll Number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? rollNo = prefs.getString('user_roll');

      if (rollNo == null) throw "Session expired. Please log in again.";

      // 2. Fetch Configuration from Firestore
      var config = await FirebaseFirestore.instance.collection('attendance_config').doc('settings').get();
      if (!config.exists) throw "Attendance configuration not found.";

      bool isAnytimeAllowed = config.data()?['allowAnytime'] ?? false;
      double targetLat = (config.data()?['latitude'] ?? 0.0).toDouble();
      double targetLng = (config.data()?['longitude'] ?? 0.0).toDouble();
      double targetRadius = (config.data()?['radius'] ?? 1000).toDouble();

      // 3. Dynamic Time Slot Logic
      DateTime now = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(now);
      String slot = "";

      if (isAnytimeAllowed) {
        slot = "Manual";
      } else {
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

      // 4. Check for Duplicates using Roll Number
      var existingRecord = await FirebaseFirestore.instance
          .collection('daily_attendance')
          .where('studentUid', isEqualTo: rollNo) // Matches your SharedPreferences ID
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

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 6. Distance Check
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          targetLat,
          targetLng
      );

      if (distance > targetRadius) {
        throw "Outside premises: ${distance.toInt()}m away.";
      }

      // 7. Save Record linked to Roll Number
      await FirebaseFirestore.instance.collection('daily_attendance').add({
        'studentUid': rollNo,
        'status': 'Present',
        'slot': slot,
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$slot Attendance Marked Present!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Text(
                "Verify your location to mark attendance",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF00897B))
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text("MARK ATTENDANCE NOW",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}