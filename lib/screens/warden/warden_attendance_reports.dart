import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WardenAttendanceReports extends StatefulWidget {
  const WardenAttendanceReports({super.key});

  @override
  State<WardenAttendanceReports> createState() =>
      _WardenAttendanceReportsState();
}

class _WardenAttendanceReportsState extends State<WardenAttendanceReports> {
  static const Color portalBlue = Color(0xFF0077C2);
  static const Color portalTeal = Color(0xFF438A7F);
  static const Color pageBg = Color(0xFFF3F6FF);

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'Morning Session';

  Future<_AttendanceReportData>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _refreshReport();
  }

  void _refreshReport() {
    _reportFuture = _fetchAttendanceReport();
  }

  Future<_AttendanceReportData> _fetchAttendanceReport() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slotAliases = _slotAliases(_selectedSlot);

    final usersQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    final attendanceQuery = FirebaseFirestore.instance
        .collection('daily_attendance')
        .where('date', isEqualTo: formattedDate)
        .where('slot', whereIn: slotAliases)
        .get();

    final results = await Future.wait([usersQuery, attendanceQuery]);
    final usersSnap = results[0];
    final attendanceSnap = results[1];

    final statusByStudentUid = <String, String>{};
    for (final doc in attendanceSnap.docs) {
      final data = doc.data();
      final studentUid =
          (data['studentUid'] ?? data['uid'] ?? data['rollNo'] ?? '')
              .toString();
      if (studentUid.isEmpty) continue;

      final status = (data['status'] ?? 'Absent').toString();
      final existing = statusByStudentUid[studentUid];
      if (existing == 'Present') continue;
      statusByStudentUid[studentUid] =
          status == 'Present' ? 'Present' : 'Absent';
    }

    final students = usersSnap.docs.map((doc) {
      final data = doc.data();
      final rollNo = (data['rollNo'] ?? doc.id).toString();
      final status =
          statusByStudentUid[rollNo] == 'Present' ? 'Present' : 'Absent';

      return _StudentAttendance(
        name: (data['name'] ?? 'Unknown Student').toString(),
        rollNo: rollNo,
        hostel: (data['hostel'] ?? 'Unassigned Hostel').toString(),
        status: status,
        photoUrl: data['photoUrl']?.toString(),
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final grouped = <String, List<_StudentAttendance>>{};
    for (final student in students) {
      grouped.putIfAbsent(student.hostel, () => []).add(student);
    }

    final hostelReports = grouped.entries.map((entry) {
      final present = entry.value.where((student) => student.isPresent).length;
      final total = entry.value.length;
      return _HostelAttendance(
        hostel: entry.key,
        students: entry.value,
        present: present,
        absent: total - present,
      );
    }).toList()
      ..sort((a, b) => a.hostel.compareTo(b.hostel));

    final present = students.where((student) => student.isPresent).length;
    final total = students.length;

    return _AttendanceReportData(
      students: students,
      hostels: hostelReports,
      total: total,
      present: present,
      absent: total - present,
    );
  }

  List<String> _slotAliases(String slot) {
    if (slot == 'Night Session') {
      return const ['Night Session', 'Night', 'Manual Night'];
    }
    return const ['Morning Session', 'Morning', 'Manual Morning'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: FutureBuilder<_AttendanceReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: portalBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load attendance report: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final report = snapshot.data ?? _AttendanceReportData.empty();

          return RefreshIndicator(
            color: portalBlue,
            onRefresh: () async {
              setState(_refreshReport);
              await _reportFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildControls(),
                  const SizedBox(height: 20),
                  _buildSummaryCards(report),
                  const SizedBox(height: 22),
                  _buildHostelSnapshots(report),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Reports',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Monitor hostel-wise attendance for the selected date and session.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return _DashboardCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final dateButton = OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
            style: OutlinedButton.styleFrom(
              foregroundColor: portalBlue,
              side: BorderSide(color: portalBlue.withValues(alpha: 0.25)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );

          final slotToggle = SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Morning Session',
                label: Text('Morning Session'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment<String>(
                value: 'Night Session',
                label: Text('Night Session'),
                icon: Icon(Icons.nights_stay_outlined),
              ),
            ],
            selected: {_selectedSlot},
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : portalBlue,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? portalBlue
                    : Colors.white,
              ),
              side: WidgetStateProperty.all(
                BorderSide(color: portalBlue.withValues(alpha: 0.22)),
              ),
            ),
            onSelectionChanged: (selection) {
              setState(() {
                _selectedSlot = selection.first;
                _refreshReport();
              });
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateButton,
                const SizedBox(height: 12),
                slotToggle,
              ],
            );
          }

          return Row(
            children: [
              dateButton,
              const SizedBox(width: 16),
              Expanded(
                  child: Align(
                      alignment: Alignment.centerRight, child: slotToggle)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(_AttendanceReportData report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 760
            ? constraints.maxWidth
            : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              width: cardWidth,
              title: 'Total Hostel Students',
              value: report.total.toString(),
              icon: Icons.groups_rounded,
              accent: portalBlue,
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Present',
              value: report.present.toString(),
              icon: Icons.check_circle_rounded,
              accent: const Color(0xFF16A34A),
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Absent',
              value: report.absent.toString(),
              icon: Icons.cancel_rounded,
              accent: const Color(0xFFDC2626),
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Overall Attendance %',
              value: '${report.percentage.toStringAsFixed(1)}%',
              icon: Icons.pie_chart_rounded,
              accent: portalTeal,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHostelSnapshots(_AttendanceReportData report) {
    if (report.hostels.isEmpty) {
      return const _DashboardCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No hostel students found.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final cardWidth =
            isNarrow ? constraints.maxWidth : (constraints.maxWidth - 18) / 2;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: report.hostels
              .map(
                (hostel) => SizedBox(
                  width: cardWidth,
                  child: _HostelSnapshotCard(hostel: hostel),
                ),
              )
              .toList(),
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

    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _refreshReport();
    });
  }
}

class _HostelSnapshotCard extends StatelessWidget {
  const _HostelSnapshotCard({required this.hostel});

  final _HostelAttendance hostel;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${hostel.hostel} Hostel',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _WardenAttendanceReportsState.portalBlue
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${hostel.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: _WardenAttendanceReportsState.portalBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HostelMiniStat(
                  label: 'Present',
                  value: hostel.present.toString(),
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HostelMiniStat(
                  label: 'Absent',
                  value: hostel.absent.toString(),
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HostelMiniStat(
                  label: 'Total',
                  value: hostel.total.toString(),
                  color: _WardenAttendanceReportsState.portalTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 330,
            child: ListView.separated(
              itemCount: hostel.students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _StudentAttendanceTile(student: hostel.students[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentAttendanceTile extends StatelessWidget {
  const _StudentAttendanceTile({required this.student});

  final _StudentAttendance student;

  @override
  Widget build(BuildContext context) {
    final image = _profileImage(student.photoUrl);
    final statusColor =
        student.isPresent ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _WardenAttendanceReportsState.portalBlue
                .withValues(alpha: 0.12),
            backgroundImage: image,
            child: image == null
                ? const Icon(
                    Icons.person_rounded,
                    color: _WardenAttendanceReportsState.portalBlue,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Roll No: ${student.rollNo}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(status: student.status, color: statusColor),
        ],
      ),
    );
  }

  ImageProvider? _profileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) return NetworkImage(photoUrl);

    try {
      final cleanBase64 =
          photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
      return MemoryImage(base64Decode(cleanBase64));
    } catch (_) {
      return null;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HostelMiniStat extends StatelessWidget {
  const _HostelMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _DashboardCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: accent.withValues(alpha: 0.12),
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
                      color: Color(0xFF1E293B),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AttendanceReportData {
  const _AttendanceReportData({
    required this.students,
    required this.hostels,
    required this.total,
    required this.present,
    required this.absent,
  });

  factory _AttendanceReportData.empty() {
    return const _AttendanceReportData(
      students: [],
      hostels: [],
      total: 0,
      present: 0,
      absent: 0,
    );
  }

  final List<_StudentAttendance> students;
  final List<_HostelAttendance> hostels;
  final int total;
  final int present;
  final int absent;

  double get percentage => total == 0 ? 0 : (present / total) * 100;
}

class _HostelAttendance {
  const _HostelAttendance({
    required this.hostel,
    required this.students,
    required this.present,
    required this.absent,
  });

  final String hostel;
  final List<_StudentAttendance> students;
  final int present;
  final int absent;

  int get total => students.length;
  double get percentage => total == 0 ? 0 : (present / total) * 100;
}

class _StudentAttendance {
  const _StudentAttendance({
    required this.name,
    required this.rollNo,
    required this.hostel,
    required this.status,
    required this.photoUrl,
  });

  final String name;
  final String rollNo;
  final String hostel;
  final String status;
  final String? photoUrl;

  bool get isPresent => status == 'Present';
}
