import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceConfigView extends StatefulWidget {
  const AttendanceConfigView({super.key});
  @override
  State<AttendanceConfigView> createState() => _AttendanceConfigViewState();
}

class _AttendanceConfigViewState extends State<AttendanceConfigView> {
  // Geofence Controllers
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  bool _allowAnytime = false;

  // Existing Slot 1 (Morning)
  TimeOfDay _startTime1 = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime1 = const TimeOfDay(hour: 16, minute: 0);

  // New Feature: Slot 2 (Night)
  TimeOfDay _startTime2 = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _endTime2 = const TimeOfDay(hour: 21, minute: 0);

  // Helper to format time for Firestore (e.g., 9:05 instead of 9:5)
  String _formatTimeOfDay(TimeOfDay tod) {
    final String hour = tod.hour.toString();
    final String minute = tod.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance.collection('attendance_config').doc('settings').set({
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'radius': double.parse(_radiusController.text),
        'allowAnytime': _allowAnytime, // Save the toggle state
        'morning_start': _formatTimeOfDay(_startTime1),
        'morning_end': _formatTimeOfDay(_endTime1),
        'night_start': _formatTimeOfDay(_startTime2),
        'night_end': _formatTimeOfDay(_endTime2),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Updated Successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Interactive Time Picker Method
  Future<void> _selectTimeRange(String title, TimeOfDay currentStart, TimeOfDay currentEnd, Function(TimeOfDay, TimeOfDay) onUpdate) async {
    TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: currentStart,
      helpText: "SELECT START TIME: $title",
    );
    if (start == null) return;

    if (!mounted) return;

    TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: currentEnd,
      helpText: "SELECT END TIME: $title",
    );
    if (end == null) return;

    onUpdate(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Setup", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGeofenceFields(),
            const Divider(height: 40),

            // EMERGENCY TOGGLE SECTION
            SwitchListTile(
              title: const Text("Allow Anytime Attendance", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Enable this to bypass time restrictions for emergencies."),
              value: _allowAnytime,
              onChanged: (val) => setState(() => _allowAnytime = val),
              activeColor: Colors.redAccent,
            ),

            const SizedBox(height: 20),
            const Text("ATTENDANCE TIME WINDOWS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),

            // UPDATED: Interactive Morning Slot
            _buildTimePickerTile(
              "Morning Slot",
              _startTime1,
              _endTime1,
                  () => _selectTimeRange("Morning", _startTime1, _endTime1, (s, e) => setState(() {
                _startTime1 = s;
                _endTime1 = e;
              })),
            ),

            // UPDATED: Interactive Night Slot
            _buildTimePickerTile(
              "Night Slot",
              _startTime2,
              _endTime2,
                  () => _selectTimeRange("Night", _startTime2, _endTime2, (s, e) => setState(() {
                _startTime2 = s;
                _endTime2 = e;
              })),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SAVE AND INITIALIZE DB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Helper with onTap handler
  Widget _buildTimePickerTile(String title, TimeOfDay start, TimeOfDay end, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap, // Now handles the click!
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${start.format(context)} to ${end.format(context)}", style: const TextStyle(color: Colors.indigo)),
        trailing: const Icon(Icons.access_time_filled, color: Colors.grey),
      ),
    );
  }

  Widget _buildGeofenceFields() {
    return Column(
      children: [
        TextField(controller: _latController, decoration: const InputDecoration(labelText: "Hostel Latitude", prefixIcon: Icon(Icons.location_on))),
        const SizedBox(height: 10),
        TextField(controller: _lngController, decoration: const InputDecoration(labelText: "Hostel Longitude", prefixIcon: Icon(Icons.location_searching))),
        const SizedBox(height: 10),
        TextField(controller: _radiusController, decoration: const InputDecoration(labelText: "Allowed Radius (meters)", prefixIcon: Icon(Icons.radar))),
      ],
    );
  }
}