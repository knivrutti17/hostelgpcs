import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import 'package:intl/intl.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  // Store attendance data mapped by date
  Map<DateTime, List<dynamic>> _attendanceLogs = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _fetchHistory();
  }

  // UPDATED: Fetch history using Roll Number session
  void _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rollNo = prefs.getString('user_roll'); // Matches your custom login key

      if (rollNo == null) {
        if (mounted) setState(() => _isInitialLoading = false);
        return;
      }

      // Query using the student's Roll Number as the UID
      var snapshot = await FirebaseFirestore.instance
          .collection('daily_attendance')
          .where('studentUid', isEqualTo: rollNo)
          .get();

      Map<DateTime, List<dynamic>> data = {};
      for (var doc in snapshot.docs) {
        final Map<String, dynamic> logData = doc.data();
        if (logData['date'] != null) {
          DateTime date = DateTime.parse(logData['date']);
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);

          if (data[normalizedDate] == null) data[normalizedDate] = [];
          data[normalizedDate]!.add(logData);
        }
      }

      if (mounted) {
        setState(() {
          _attendanceLogs = data;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching history: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get logs for the currently selected day
    final normalizedSelected = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final selectedLogs = _attendanceLogs[normalizedSelected] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _attendanceLogs[DateTime(day.year, day.month, day.day)] ?? [];
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: selectedLogs.isEmpty
                ? const Center(
                child: Text("No attendance records for this day",
                    style: TextStyle(color: Colors.grey, fontSize: 14)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: selectedLogs.length,
              itemBuilder: (context, index) {
                var log = selectedLogs[index];
                var timestamp = log['timestamp'] as Timestamp?;
                String timeStr = timestamp != null
                    ? DateFormat('hh:mm a').format(timestamp.toDate())
                    : "N/A";

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    title: Text("${log['slot'] ?? 'Manual'} Attendance",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Time: $timeStr"),
                    trailing: const Text("Present",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}