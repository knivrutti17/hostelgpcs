import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceConfigView extends StatefulWidget {
  const AttendanceConfigView({super.key});
  @override
  State<AttendanceConfigView> createState() => _AttendanceConfigViewState();
}

class _AttendanceConfigViewState extends State<AttendanceConfigView> {
  // These controllers are essential for the Latitude/Longitude input
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _radiusController = TextEditingController();

  String _startTime = "19:00";
  String _endTime = "21:00";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  // Fetches current settings to show what is already in the database
  Future<void> _loadExistingSettings() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('attendance_config').doc('settings').get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _latController.text = data['latitude'].toString();
          _longController.text = data['longitude'].toString();
          _radiusController.text = data['radius'].toString();
          _startTime = data['startTime'] ?? "19:00";
          _endTime = data['endTime'] ?? "21:00";
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Allows Admin to pick the start and end times
  Future<void> _selectTime(bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) {
      setState(() {
        String formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStart) _startTime = formatted; else _endTime = formatted;
      });
    }
  }

  // Saves the configuration to Firestore
  void _saveSettings() async {
    try {
      await FirebaseFirestore.instance.collection('attendance_config').doc('settings').set({
        'latitude': double.parse(_latController.text.trim()),
        'longitude': double.parse(_longController.text.trim()),
        'radius': int.parse(_radiusController.text.trim()),
        'startTime': _startTime,
        'endTime': _endTime,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved Successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Setup", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text("Hostel Geofence Configuration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 20),
            TextField(
                controller: _latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hostel Latitude", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _longController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hostel Longitude", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Allowed Radius (meters)", border: OutlineInputBorder())
            ),
            const SizedBox(height: 25),
            const Text("Attendance Time Window", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _selectTime(true),
                      icon: const Icon(Icons.access_time),
                      label: Text("Start: $_startTime")
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _selectTime(false),
                      icon: const Icon(Icons.access_time),
                      label: Text("End: $_endTime")
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white
                ),
                child: const Text("SAVE AND INITIALIZE DB", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}