import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHistory();
  }

  void _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('daily_attendance')
        .where('studentUid', isEqualTo: uid)
        .get();

    Map<DateTime, List<dynamic>> data = {};
    for (var doc in snapshot.docs) {
      // Parse the date string from Firestore
      DateTime date = DateTime.parse(doc['date']);
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);

      if (data[normalizedDate] == null) data[normalizedDate] = [];
      data[normalizedDate]!.add(doc.data());
    }

    if (mounted) {
      setState(() => _attendanceLogs = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get logs for the currently selected day
    final selectedLogs = _attendanceLogs[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
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
              markerDecoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: selectedLogs.isEmpty
                ? const Center(child: Text("No attendance records for this day"))
                : ListView.builder(
              itemCount: selectedLogs.length,
              itemBuilder: (context, index) {
                var log = selectedLogs[index];
                var timestamp = log['timestamp'] as Timestamp?;
                String timeStr = timestamp != null
                    ? DateFormat('hh:mm a').format(timestamp.toDate())
                    : "N/A";

                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text("${log['slot']} Attendance"),
                  subtitle: Text("Time: $timeStr"),
                  trailing: const Text("Present", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}