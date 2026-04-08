import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HODAttendanceReports extends StatefulWidget {
  const HODAttendanceReports({super.key});

  @override
  State<HODAttendanceReports> createState() => _HODAttendanceReportsState();
}

class _HODAttendanceReportsState extends State<HODAttendanceReports> {
  static const Color _primaryTeal = Color(0xFF438A7F);
  static const String _branch = 'Information technology';

  DateTime _selectedDate = DateTime.now();
  String _selectedSession = 'Morning';

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('yyyy-MM-dd').format(_selectedDate);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, studentSnapshot) {
        final studentDocs = (studentSnapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == _branch;
        }).toList();
        final int totalStudents = studentDocs.length;
        final allowedIds = studentDocs.map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('daily_attendance')
              .where('date', isEqualTo: formattedDate)
              .where('slot', isEqualTo: _selectedSession)
              .where('status', isEqualTo: 'Present')
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            final attendanceDocs = (attendanceSnapshot.data?.docs ?? [])
                .where((doc) {
                  final data = doc.data();
                  final studentId =
                      (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                          .toString();
                  return allowedIds.contains(studentId);
                })
                .toList();
            final int present = attendanceDocs.length;
            final int absent = (totalStudents - present).clamp(0, totalStudents);
            final double percentage = totalStudents == 0
                ? 0
                : (present / totalStudents) * 100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Reports',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22312D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track daily hostel attendance for the Information technology branch.',
                    style: TextStyle(
                      color: Color(0xFF73827E),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                side: BorderSide(
                                  color: _primaryTeal.withOpacity(0.18),
                                ),
                              ),
                              onPressed: _pickDate,
                              icon: const Icon(
                                Icons.calendar_month_rounded,
                                color: _primaryTeal,
                              ),
                              label: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  color: Color(0xFF22312D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'Morning',
                                  label: Text('Morning Session'),
                                  icon: Icon(Icons.wb_sunny_outlined),
                                ),
                                ButtonSegment<String>(
                                  value: 'Night',
                                  label: Text('Night Session'),
                                  icon: Icon(Icons.nightlight_outlined),
                                ),
                              ],
                              selected: {_selectedSession},
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? Colors.white
                                      : _primaryTeal,
                                ),
                                backgroundColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? _primaryTeal
                                      : Colors.white,
                                ),
                                side: WidgetStateProperty.all(
                                  BorderSide(
                                    color: _primaryTeal.withOpacity(0.20),
                                  ),
                                ),
                              ),
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _selectedSession = selection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        title: 'Total IT Students',
                        value: totalStudents.toString(),
                        icon: Icons.groups_rounded,
                        accent: _primaryTeal,
                      ),
                      _StatCard(
                        title: 'Present',
                        value: present.toString(),
                        icon: Icons.check_circle_rounded,
                        accent: const Color(0xFF2E9E6F),
                      ),
                      _StatCard(
                        title: 'Absent',
                        value: absent.toString(),
                        icon: Icons.cancel_rounded,
                        accent: const Color(0xFFE25B52),
                      ),
                      _StatCard(
                        title: 'Overall Attendance %',
                        value: '${percentage.toStringAsFixed(1)}%',
                        icon: Icons.pie_chart_rounded,
                        accent: const Color(0xFF2E7DFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Session Snapshot',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF22312D),
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primaryTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: _downloadPdfReport,
                                icon: const Icon(Icons.picture_as_pdf_rounded),
                                label: const Text('Download PDF Report'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Selected day: ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)} • $_selectedSession Session',
                            style: const TextStyle(
                              color: Color(0xFF73827E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (attendanceDocs.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAF9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'No attendance records found for the selected date and session.',
                                style: TextStyle(
                                  color: Color(0xFF73827E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: attendanceDocs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final data = attendanceDocs[index].data();
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FAF9),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            _primaryTeal.withOpacity(0.12),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: _primaryTeal,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (data['studentName'] ??
                                                      data['studentUid'] ??
                                                      'Student')
                                                  .toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF22312D),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Verified status: ${data['status'] ?? 'Present'}',
                                              style: const TextStyle(
                                                color: Color(0xFF73827E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryTeal.withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Present',
                                          style: TextStyle(
                                            color: _primaryTeal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _downloadPdfReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF report generation placeholder for ${DateFormat('dd MMM yyyy').format(_selectedDate)} ($_selectedSession Session).',
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withOpacity(0.12),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF22312D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF73827E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
