import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/services/admin_attendance_pdf_service.dart';
import 'package:gpcs_hostel_portal/styles.dart';
import 'package:intl/intl.dart';

enum _AttendanceStatusFilter { all, present, absent }

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  _AttendanceStatusFilter _statusFilter = _AttendanceStatusFilter.all;
  String _searchQuery = "";
  bool _isDownloading = false;

  String get _selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _selectedSession => _tabController.index == 0 ? 'Morning' : 'Night';
  bool get _isTodaySelected => DateUtils.isSameDay(_selectedDate, DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = AppColors.backgroundWhite;
    final pageColor = AppColors.sidebarBg.withOpacity(0.28);

    return Container(
      color: pageColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, primaryColor, surfaceColor),
                  const SizedBox(height: 20),
                  _buildCalendarCard(theme, primaryColor, surfaceColor),
                  const SizedBox(height: 16),
                  _buildSessionTabs(theme, primaryColor, surfaceColor),
                  const SizedBox(height: 16),
                  _buildAttendanceStream(
                    theme: theme,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    viewportHeight: constraints.maxHeight,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color primaryColor, Color surfaceColor) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Attendance Dashboard',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monitor daily attendance, sessions, and verification updates in real time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withOpacity(0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                'Live Attendance Feed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme, Color primaryColor, Color surfaceColor) {
    final visibleDates = List<DateTime>.generate(
      11,
      (index) => DateUtils.addDaysToDate(_selectedDate, index - 5),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(surfaceColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined, color: primaryColor),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Calendar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack,
                        ),
                      ),
                      Text(
                        'Selected: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedDate = DateUtils.addDaysToDate(_selectedDate, -1);
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _selectedDate = DateUtils.addDaysToDate(_selectedDate, 1);
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Pick Date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withOpacity(0.35)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleDates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = visibleDates[index];
                final isSelected = DateUtils.isSameDay(date, _selectedDate);

                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : AppColors.sidebarBg.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected ? Colors.white70 : primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd').format(date),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTabs(ThemeData theme, Color primaryColor, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _panelDecoration(surfaceColor),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.blueGrey.shade700,
        labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Morning Session'),
          Tab(text: 'Night Session'),
        ],
      ),
    );
  }

  Widget _buildAttendanceStream({
    required ThemeData theme,
    required Color primaryColor,
    required Color surfaceColor,
    required double viewportHeight,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('daily_attendance')
              .where('date', isEqualTo: _selectedDateKey)
              .where('status', isEqualTo: 'Present')
              .snapshots(),
          builder: (context, dailySnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('daily_attendance')
                  .where('date', isEqualTo: _selectedDateKey)
                  .where('slot', isEqualTo: _selectedSession)
                  .snapshots(),
              builder: (context, sessionSnapshot) {
                if (userSnapshot.hasError || dailySnapshot.hasError || sessionSnapshot.hasError) {
                  return _buildErrorState(theme);
                }

                if (userSnapshot.connectionState == ConnectionState.waiting ||
                    dailySnapshot.connectionState == ConnectionState.waiting ||
                    sessionSnapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }

                final users = userSnapshot.data?.docs ?? const [];
                final dailyDocs = dailySnapshot.data?.docs ?? const [];
                final sessionDocs = sessionSnapshot.data?.docs ?? const [];
                final sessionRows = _buildAttendanceRows(users: users, attendanceDocs: sessionDocs);
                final filteredRows = _applyFilters(sessionRows);

                final totalStudents = users.length;
                final presentIds = dailyDocs
                    .map((doc) => (doc.data()['studentUid'] ?? '').toString())
                    .where((id) => id.isNotEmpty)
                    .toSet();
                final presentToday = presentIds.length;
                final absentToday = totalStudents - presentToday;
                final attendancePercent =
                    totalStudents == 0 ? 0.0 : (presentToday / totalStudents) * 100;
                final listHeight = viewportHeight < 760 ? 420.0 : viewportHeight * 0.58;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(
                      theme: theme,
                      primaryColor: primaryColor,
                      totalStudents: totalStudents,
                      presentToday: presentToday,
                      absentToday: absentToday,
                      attendancePercent: attendancePercent,
                    ),
                    const SizedBox(height: 16),
                    _buildControlBar(theme, primaryColor, surfaceColor, sessionRows),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: listHeight,
                      child: _buildAttendanceList(
                        theme: theme,
                        primaryColor: primaryColor,
                        surfaceColor: surfaceColor,
                        rows: filteredRows,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatsGrid({
    required ThemeData theme,
    required Color primaryColor,
    required int totalStudents,
    required int presentToday,
    required int absentToday,
    required double attendancePercent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 920;
        final cardWidth = isCompact ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _DashboardStatCard(
              title: 'Total Students',
              value: totalStudents.toString(),
              subtitle: 'All active students',
              icon: Icons.groups_2_outlined,
              width: cardWidth,
              color: primaryColor,
              onTap: () => setState(() => _statusFilter = _AttendanceStatusFilter.all),
            ),
            _DashboardStatCard(
              title: 'Present Today',
              value: presentToday.toString(),
              subtitle: 'Live present records',
              icon: Icons.verified_user_outlined,
              width: cardWidth,
              color: primaryColor,
              onTap: _showPresentStudentsDialog,
            ),
            _DashboardStatCard(
              title: 'Absent Today',
              value: absentToday.toString(),
              subtitle: 'Not marked yet',
              icon: Icons.person_off_outlined,
              width: cardWidth,
              color: theme.colorScheme.error,
              onTap: () => setState(() => _statusFilter = _AttendanceStatusFilter.absent),
            ),
            _DashboardStatCard(
              title: 'Attendance %',
              value: '${attendancePercent.toStringAsFixed(1)}%',
              subtitle: 'Daily live coverage',
              icon: Icons.analytics_outlined,
              width: cardWidth,
              color: primaryColor,
              onTap: () => setState(() => _statusFilter = _AttendanceStatusFilter.present),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlBar(
    ThemeData theme,
    Color primaryColor,
    Color surfaceColor,
    List<_AttendanceStudentRow> sessionRows,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(surfaceColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final searchField = SizedBox(
            width: isCompact ? double.infinity : 320,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by student, roll no, or room',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                filled: true,
                fillColor: AppColors.sidebarBg.withOpacity(0.22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );

          final filters = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterChip(theme, primaryColor, 'All', _AttendanceStatusFilter.all),
              _buildFilterChip(theme, primaryColor, 'Present', _AttendanceStatusFilter.present),
              _buildFilterChip(theme, primaryColor, 'Absent', _AttendanceStatusFilter.absent),
            ],
          );

          final reportButton = FilledButton.icon(
            onPressed: sessionRows.isEmpty || _isDownloading ? null : () => _downloadReport(sessionRows),
            icon: _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_isTodaySelected ? "Download Today's Report" : 'Download Session Report'),
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [searchField, const SizedBox(height: 12), filters, const SizedBox(height: 12), reportButton],
            );
          }

          return Row(
            children: [
              searchField,
              const SizedBox(width: 16),
              Expanded(child: filters),
              const SizedBox(width: 16),
              reportButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList({
    required ThemeData theme,
    required Color primaryColor,
    required Color surfaceColor,
    required List<_AttendanceStudentRow> rows,
  }) {
    if (rows.isEmpty) {
      return Container(
        decoration: _panelDecoration(surfaceColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late_outlined, size: 48, color: Colors.blueGrey.shade300),
              const SizedBox(height: 12),
              Text(
                'No matching attendance records found.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Try another date, session, or filter combination.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 980) {
          return _buildDesktopTable(theme, primaryColor, surfaceColor, rows);
        }
        return _buildMobileList(theme, primaryColor, surfaceColor, rows);
      },
    );
  }

  Widget _buildDesktopTable(
    ThemeData theme,
    Color primaryColor,
    Color surfaceColor,
    List<_AttendanceStudentRow> rows,
  ) {
    return Container(
      decoration: _panelDecoration(surfaceColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.sidebarBg.withOpacity(0.35)),
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Room No')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Time of Marking')),
                DataColumn(label: Text('Verification')),
              ],
              rows: rows.map((row) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.studentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(
                            row.rollNo,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(row.roomNo)),
                    DataCell(_StatusPill(label: row.status, isPresent: row.status == 'Present', primaryColor: primaryColor)),
                    DataCell(Text(row.formattedTime)),
                    DataCell(Text(row.verificationMethod)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    ThemeData theme,
    Color primaryColor,
    Color surfaceColor,
    List<_AttendanceStudentRow> rows,
  ) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = rows[index];
        final isPresent = row.status == 'Present';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _panelDecoration(surfaceColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPresent
                        ? primaryColor.withOpacity(0.12)
                        : theme.colorScheme.error.withOpacity(0.12),
                    child: Icon(
                      isPresent ? Icons.verified_user_outlined : Icons.person_off_outlined,
                      color: isPresent ? primaryColor : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.studentName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${row.rollNo} | Room ${row.roomNo}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(label: row.status, isPresent: isPresent, primaryColor: primaryColor),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoBadge(icon: Icons.schedule_outlined, label: 'Time', value: row.formattedTime, primaryColor: primaryColor),
                  _InfoBadge(icon: Icons.fingerprint_outlined, label: 'Verification', value: row.verificationMethod, primaryColor: primaryColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load attendance data right now.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    Color primaryColor,
    String label,
    _AttendanceStatusFilter value,
  ) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: primaryColor.withOpacity(0.12),
      checkmarkColor: primaryColor,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isSelected ? primaryColor : Colors.blueGrey.shade700,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: isSelected ? primaryColor : Colors.blueGrey.shade100),
    );
  }

  List<_AttendanceStudentRow> _buildAttendanceRows({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> attendanceDocs,
  }) {
    final attendanceByStudent = {
      for (final doc in attendanceDocs) (doc.data()['studentUid'] ?? doc.id).toString(): doc.data(),
    };

    final rows = users.map((userDoc) {
      final user = userDoc.data();
      final studentUid = (user['uid'] ?? userDoc.id).toString();
      final attendance = attendanceByStudent[studentUid];
      final isPresent = attendance != null && (attendance['status'] ?? 'Present') == 'Present';
      final timestamp = attendance?['timestamp'] as Timestamp?;

      return _AttendanceStudentRow(
        studentName: (user['name'] ?? 'Unknown Student').toString(),
        rollNo: (user['rollNo'] ?? studentUid).toString(),
        roomNo: (user['roomNo'] ?? 'N/A').toString(),
        status: isPresent ? 'Present' : 'Absent',
        verificationMethod: isPresent
            ? (attendance?['verifiedBy'] ?? attendance?['markedBy'] ?? 'GPS').toString()
            : '--',
        markedAt: timestamp?.toDate(),
      );
    }).toList();

    rows.sort((a, b) {
      if (a.status != b.status) return a.status == 'Present' ? -1 : 1;
      return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });
    return rows;
  }

  List<_AttendanceStudentRow> _applyFilters(List<_AttendanceStudentRow> rows) {
    return rows.where((row) {
      final matchesSearch = _searchQuery.isEmpty ||
          row.studentName.toLowerCase().contains(_searchQuery) ||
          row.rollNo.toLowerCase().contains(_searchQuery) ||
          row.roomNo.toLowerCase().contains(_searchQuery);

      final matchesStatus = switch (_statusFilter) {
        _AttendanceStatusFilter.all => true,
        _AttendanceStatusFilter.present => row.status == 'Present',
        _AttendanceStatusFilter.absent => row.status == 'Absent',
      };

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Attendance Date',
    );
    if (picked != null) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _downloadReport(List<_AttendanceStudentRow> rows) async {
    setState(() => _isDownloading = true);
    try {
      await AdminAttendancePdfService.generateDailyReport(
        date: _selectedDate,
        session: _selectedSession,
        entries: rows
            .map(
              (row) => AttendancePdfEntry(
                studentName: row.studentName,
                rollNo: row.rollNo,
                roomNo: row.roomNo,
                status: row.status,
                timeOfMarking: row.formattedTime,
                verificationMethod: row.verificationMethod,
              ),
            )
            .toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Attendance report is ready.'), backgroundColor: Theme.of(context).colorScheme.primary),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _showPresentStudentsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final primaryColor = theme.colorScheme.primary;

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 920,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Present Students on ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 420,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'student')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('daily_attendance')
                            .where('date', isEqualTo: _selectedDateKey)
                            .where('status', isEqualTo: 'Present')
                            .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          if (!userSnapshot.hasData || !attendanceSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: primaryColor));
                          }

                          final userMap = {
                            for (final doc in userSnapshot.data!.docs) doc.id: doc.data(),
                          };
                          final presentRows = attendanceSnapshot.data!.docs.map((doc) {
                            final data = doc.data();
                            final studentUid = (data['studentUid'] ?? '').toString();
                            final user = userMap[studentUid] ?? <String, dynamic>{};
                            final markedAt = (data['timestamp'] as Timestamp?)?.toDate();
                            return _PresentStudentRow(
                              studentName: (user['name'] ?? data['studentName'] ?? 'Unknown Student').toString(),
                              roomNo: (user['roomNo'] ?? 'N/A').toString(),
                              session: (data['slot'] ?? 'Manual').toString(),
                              verificationMethod: (data['verifiedBy'] ?? data['markedBy'] ?? 'GPS').toString(),
                              attendanceTime: markedAt == null ? '--' : DateFormat('hh:mm a').format(markedAt),
                            );
                          }).toList()
                            ..sort((a, b) => a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()));

                          if (presentRows.isEmpty) {
                            return const Center(child: Text('No students marked present for this date.'));
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 760) {
                                return SingleChildScrollView(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppColors.sidebarBg.withOpacity(0.35)),
                                      columns: const [
                                        DataColumn(label: Text('Student Name')),
                                        DataColumn(label: Text('Room Number')),
                                        DataColumn(label: Text('Attendance Time')),
                                        DataColumn(label: Text('Session')),
                                        DataColumn(label: Text('Verification')),
                                      ],
                                      rows: presentRows
                                          .map(
                                            (row) => DataRow(
                                              cells: [
                                                DataCell(Text(row.studentName)),
                                                DataCell(Text(row.roomNo)),
                                                DataCell(Text(row.attendanceTime)),
                                                DataCell(Text(row.session)),
                                                DataCell(Text(row.verificationMethod)),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: presentRows.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final row = presentRows[index];
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.sidebarBg.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(row.studentName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('Room ${row.roomNo} | ${row.attendanceTime}'),
                                        Text('${row.session} | ${row.verificationMethod}'),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _panelDecoration(Color surfaceColor) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _AttendanceStudentRow {
  const _AttendanceStudentRow({
    required this.studentName,
    required this.rollNo,
    required this.roomNo,
    required this.status,
    required this.verificationMethod,
    required this.markedAt,
  });

  final String studentName;
  final String rollNo;
  final String roomNo;
  final String status;
  final String verificationMethod;
  final DateTime? markedAt;

  String get formattedTime => markedAt == null ? '--' : DateFormat('hh:mm a').format(markedAt!);
}

class _PresentStudentRow {
  const _PresentStudentRow({
    required this.studentName,
    required this.roomNo,
    required this.attendanceTime,
    required this.session,
    required this.verificationMethod,
  });

  final String studentName;
  final String roomNo;
  final String attendanceTime;
  final String session;
  final String verificationMethod;
}

class _DashboardStatCard extends StatefulWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.width,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final double width;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<_DashboardStatCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _isHovering ? 1.01 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isHovering ? widget.color.withOpacity(0.32) : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovering ? 0.07 : 0.04),
                    blurRadius: _isHovering ? 22 : 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: widget.color.withOpacity(0.12),
                    child: Icon(widget.icon, color: widget.color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textBlack,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.isPresent,
    required this.primaryColor,
  });

  final String label;
  final bool isPresent;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final color = isPresent ? primaryColor : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
