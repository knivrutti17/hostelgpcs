import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/leave_report_generator.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class LeaveApprovalView extends StatefulWidget {
  const LeaveApprovalView({
    super.key,
    this.branchFilter,
    this.showAppBar = true,
  });

  final String? branchFilter;
  final bool showAppBar;

  @override
  State<LeaveApprovalView> createState() => _LeaveApprovalViewState();
}

class _LeaveApprovalViewState extends State<LeaveApprovalView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color portalBlue = Color(0xFF0077C2);
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        Column(
          children: [
            if (!widget.showAppBar)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: portalBlue,
                  indicatorWeight: 3,
                  labelColor: portalBlue,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "PENDING REQUESTS"),
                    Tab(text: "ACTION HISTORY"),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaveList('Pending'),
                  _buildHistoryPanel(),
                ],
              ),
            ),
          ],
        ),
        if (_isGeneratingPdf)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text("Preparing Official PDF...",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (!widget.showAppBar) {
      return ColoredBox(
        color: const Color(0xFFF3F6FF),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          title: const Text("Leave Management",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)),
          backgroundColor: portalBlue,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "PENDING REQUESTS"),
              Tab(text: "ACTION HISTORY"),
            ],
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildLeaveList(String status) {
    return _buildFilteredLeaveStream(
      stream: _leaveStreamForStatus(status).snapshots(),
      emptyMessage: "No $status requests found",
      builder: (docs) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          var data = docs[index].data() as Map<String, dynamic>;
          return _buildRequestCard(docs[index].id, data);
        },
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Processed Leaves",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: portalBlue)),
              ElevatedButton.icon(
                onPressed:
                    _isGeneratingPdf ? null : () => _generateHistoryPdf(),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text("EXPORT OFFICIAL PDF",
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: _buildFilteredLeaveStream(
            stream: _historyStream().snapshots(),
            emptyMessage: "No history available",
            builder: (docs) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                return _buildRequestCard(docs[index].id, data, isHistory: true);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(String docId, Map<String, dynamic> data,
      {bool isHistory = false}) {
    final studentId = _studentIdFromLeave(data);
    final duration = _leaveDurationLabel(data['startDate'], data['endDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildStudentAvatar(studentId),
        title: Text(data['studentName'] ?? "Unknown",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: FutureBuilder<DocumentSnapshot>(
            future: studentId.isEmpty
                ? null
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
            builder: (context, userSnap) {
              String room = data['roomNo']?.toString() ?? "N/A";
              if (userSnap.hasData && userSnap.data!.exists) {
                var userData = userSnap.data!.data() as Map<String, dynamic>;
                room = userData['roomNo']?.toString() ?? room;
              }
              return Text("Roll: ${data['rollNo'] ?? '--'} • Room $room",
                  style: const TextStyle(fontSize: 12));
            }),
        trailing: _statusBadge(data['status']),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _detailRow(Icons.calendar_today, "Leave Dates",
                    "${data['startDate']} to ${data['endDate']}"),
                _detailRow(Icons.timelapse, "Duration", duration),
                _detailRow(
                    Icons.info_outline, "Reason", data['reason'] ?? "Other"),
                if (isHistory &&
                    data['status'] == 'Rejected' &&
                    (data['rejectReason'] ?? '').toString().trim().isNotEmpty)
                  _detailRow(
                    Icons.cancel_outlined,
                    "Rejection Reason",
                    data['rejectReason'].toString(),
                    valueColor: Colors.red,
                  ),
                if (!isHistory) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                        onPressed: () => _showRejectDialog(docId),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red)),
                        child: const Text("REJECT"),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () => _update(docId, 'Approved'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text("APPROVE"),
                      )),
                    ],
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    Color color = Colors.orange;
    if (status == 'Approved') color = Colors.green;
    if (status == 'Rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status ?? "Pending",
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentAvatar(String studentId) {
    if (studentId.isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: portalBlue,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(studentId).get(),
      builder: (context, userSnap) {
        String? base64String;
        if (userSnap.hasData && userSnap.data!.exists) {
          final userData = userSnap.data!.data() as Map<String, dynamic>;
          base64String = userData['photoUrl']?.toString();
        }
        final avatarImage = _profileImage(base64String);

        return CircleAvatar(
          radius: 24,
          backgroundColor: portalBlue,
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        );
      },
    );
  }

  ImageProvider? _profileImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      debugPrint("Invalid student profile image: $e");
      return null;
    }
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: portalBlue),
          const SizedBox(width: 8),
          Text("$label: ",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight:
                    valueColor == null ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Text(msg,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500)),
      ),
    );
  }

  String _studentIdFromLeave(Map<String, dynamic> data) {
    return (data['studentUid'] ?? data['uid'] ?? data['rollNo'] ?? '')
        .toString();
  }

  String _leaveDurationLabel(dynamic startValue, dynamic endValue) {
    final startDate = _parseLeaveDate(startValue);
    final endDate = _parseLeaveDate(endValue);
    if (startDate == null || endDate == null) return "N/A";

    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) return "N/A";
    return "$totalDays ${totalDays == 1 ? 'Day' : 'Days'}";
  }

  DateTime? _parseLeaveDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final formats = [
      DateFormat('MMM dd yyyy'),
      DateFormat('MMM d yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd-MM-yyyy'),
    ];

    for (final format in formats) {
      try {
        final candidate = text.contains(RegExp(r'\d{4}'))
            ? text
            : '$text ${DateTime.now().year}';
        return format.parseStrict(candidate);
      } catch (_) {
        // Try the next supported date shape.
      }
    }
    return null;
  }

  Future<void> _showRejectDialog(String docId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reason for Rejection"),
          content: TextField(
            controller: reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter why this leave request is rejected",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
              child: const Text("SUBMIT"),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;
    _update(docId, 'Rejected', rejectReason: reason);
  }

  void _update(String id, String status, {String? rejectReason}) {
    final updateData = <String, dynamic>{
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'Rejected') {
      updateData['rejectReason'] = rejectReason ?? '';
    } else {
      updateData['rejectReason'] = FieldValue.delete();
    }

    FirebaseFirestore.instance.collection('leaves').doc(id).update(updateData);
  }

  Future<void> _generateHistoryPdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final historySnap = await _historyStream().get();
      final filteredDocs = await _filterDocsForBranch(historySnap.docs);

      final logoData = await rootBundle.load('assets/images/gpcslogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      final leaves =
          await LeaveReportGenerator.buildLeaveModelsWithRooms(filteredDocs);

      final pdfBytes = await LeaveReportGenerator.generateLeavePdf(
        leaves,
        logoBytes,
        logoBytes,
      );

      await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name:
              'Leave_History_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to generate PDF: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Query<Map<String, dynamic>> _leaveBaseQuery() {
    return FirebaseFirestore.instance.collection('leaves');
  }

  Query<Map<String, dynamic>> _leaveStreamForStatus(String status) {
    return _leaveBaseQuery().where('status', isEqualTo: status);
  }

  Query<Map<String, dynamic>> _historyStream() {
    return _leaveBaseQuery().where('status', whereIn: ['Approved', 'Rejected']);
  }

  Widget _buildFilteredLeaveStream({
    required Stream<QuerySnapshot> stream,
    required String emptyMessage,
    required Widget Function(List<QueryDocumentSnapshot> docs) builder,
  }) {
    if (widget.branchFilter == null) {
      return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _emptyState(emptyMessage);
          }
          return builder(docs);
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allowedIds = userSnapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final role = (data['role'] ?? '').toString().toLowerCase();
              final branch =
                  (data['branch'] ?? data['brach'] ?? '').toString().trim();
              return role == 'student' && branch == widget.branchFilter;
            })
            .map((doc) => doc.id)
            .toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentId =
                  (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                      .toString();
              return allowedIds.contains(studentId);
            }).toList();

            if (docs.isEmpty) {
              return _emptyState(emptyMessage);
            }

            return builder(docs);
          },
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _filterDocsForBranch(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (widget.branchFilter == null) {
      return docs;
    }

    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final allowedIds = usersSnap.docs
        .where((doc) {
          final data = doc.data();
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == widget.branchFilter;
        })
        .map((doc) => doc.id)
        .toSet();

    return docs.where((doc) {
      final data = doc.data();
      final studentId =
          (data['studentUid'] ?? data['uid'] ?? data['rollNo']).toString();
      return allowedIds.contains(studentId);
    }).toList();
  }
}
