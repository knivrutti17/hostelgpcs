import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  Map<DateTime, List<dynamic>> _attendanceLogs = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isInitialLoading = true;
  String _studentName = "Student";
  String _studentRoll = "";

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _fetchHistory();
  }

  void _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rollNo = prefs.getString('user_roll');

      if (rollNo == null) {
        if (mounted) setState(() => _isInitialLoading = false);
        return;
      }

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
      if (userDoc.exists) {
        _studentName = userDoc.data()?['name'] ?? "Student";
      }
      _studentRoll = rollNo;

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

  double _calculateMonthlyPercentage() {
    int totalDaysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    int presentCount = 0;

    _attendanceLogs.forEach((date, logs) {
      if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
        if (logs.isNotEmpty) presentCount++;
      }
    });

    return totalDaysInMonth == 0 ? 0 : (presentCount / totalDaysInMonth) * 100;
  }

  Future<void> _generateAttendancePdf() async {
    final pdf = pw.Document();
    final String monthYear = DateFormat('MMMM yyyy').format(_focusedDay);

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/gpcslogo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) { debugPrint("Logo not found"); }

    // Map logs to List<List<String>> for PDF Table helper
    final List<List<String>> tableData = [
      ['Date', 'Slot', 'Status', 'Time'],
    ];

    _attendanceLogs.entries
        .where((e) => e.key.month == _focusedDay.month && e.key.year == _focusedDay.year)
        .forEach((entry) {
      for (var log in entry.value) {
        tableData.add([
          DateFormat('yyyy-MM-dd').format(entry.key),
          log['slot'] ?? 'Manual',
          'Present',
          log['timestamp'] != null
              ? DateFormat('hh:mm a').format((log['timestamp'] as Timestamp).toDate())
              : "N/A"
        ]);
      }
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 50, height: 50),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    children: [
                      pw.Text("Government Polytechnic, Chhatrapati Sambhajinagar",
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Official Attendance Report - $monthYear",
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Name: $_studentName"),
                  pw.Text("Enrollment: $_studentRoll"),
                ],
              ),
              pw.Text("Monthly Attendance: ${_calculateMonthlyPercentage().toStringAsFixed(1)}%"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                context: context,
                data: tableData,
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(children: [
                    pw.SizedBox(width: 100, child: pw.Divider()),
                    pw.Text("System Generated Report", style: const pw.TextStyle(fontSize: 8)),
                  ])
                ],
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final selectedLogs = _attendanceLogs[normalizedSelected] ?? [];
    final double percentage = _calculateMonthlyPercentage();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text("Attendance History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _generateAttendancePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          )
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: const Color(0xFF00897B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMMM yyyy').format(_focusedDay),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text("Current Month Status",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  // FIXED: Used standard FontWeight.bold instead of pw.FontWeight.bold
                  child: Text("${percentage.toStringAsFixed(1)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
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
                ? const Center(child: Text("No records for this day", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: selectedLogs.length,
              itemBuilder: (context, index) {
                var log = selectedLogs[index];
                var timestamp = log['timestamp'] as Timestamp?;
                String timeStr = timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : "N/A";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 28),
                    title: Text("${log['slot'] ?? 'Manual'} Check-in", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Logged at $timeStr"),
                    trailing: const Text("PRESENT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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