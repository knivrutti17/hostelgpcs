import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // <--- ADD THIS LINE TO FIX THE ERROR

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

class _LeaveApprovalViewState extends State<LeaveApprovalView> with SingleTickerProviderStateMixin {
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
                      Text("Preparing Official PDF...", style: TextStyle(fontWeight: FontWeight.bold)),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
              const Text("Processed Leaves", style: TextStyle(fontWeight: FontWeight.bold, color: portalBlue)),
              ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : () => _generateHistoryPdf(),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text("EXPORT OFFICIAL PDF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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

  Widget _buildRequestCard(String docId, Map<String, dynamic> data, {bool isHistory = false}) {
    String studentId = data['uid'] ?? data['rollNo'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: portalBlue.withOpacity(0.1),
          child: const Icon(Icons.person, color: portalBlue),
        ),
        title: Text(data['studentName'] ?? "Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
            builder: (context, userSnap) {
              String room = data['roomNo']?.toString() ?? "N/A";
              if (userSnap.hasData && userSnap.data!.exists) {
                var userData = userSnap.data!.data() as Map<String, dynamic>;
                room = userData['roomNo']?.toString() ?? room;
              }
              return Text("Roll: ${data['rollNo'] ?? '--'} • Room $room",
                  style: const TextStyle(fontSize: 12));
            }
        ),
        trailing: _statusBadge(data['status']),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _detailRow(Icons.calendar_today, "Duration", "${data['startDate']} to ${data['endDate']}"),
                _detailRow(Icons.info_outline, "Reason", data['reason'] ?? "Other"),
                if (!isHistory) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => _update(docId, 'Rejected'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text("REJECT"),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(
                        onPressed: () => _update(docId, 'Approved'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status ?? "Pending", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: portalBlue),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _update(String id, String status) {
    FirebaseFirestore.instance.collection('leaves').doc(id).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _generateHistoryPdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      final historySnap = await _historyStream().get();
      final filteredDocs = await _filterDocsForBranch(historySnap.docs);

      Uint8List? logoBytes;
      try {
        final response = await http.get(Uri.parse('https://upload.wikimedia.org/wikipedia/en/5/52/Government_Polytechnic%2C_Aurangabad_logo.png')).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) logoBytes = response.bodyBytes;
      } catch (e) {
        debugPrint("Logo fetch failed: $e");
      }

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), width: 60, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Government Polytechnic, Chh. Sambhajinagar",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Hostel Administration Department",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text("Official Leave History Report",
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Generated on: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.grey),
          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 25,
            headers: ['Student Name', 'Room', 'Status', 'Start Date', 'End Date'],
            data: filteredDocs.map((doc) {
              var d = doc.data() as Map<String, dynamic>;
              return [
                d['studentName'] ?? "N/A",
                d['roomNo']?.toString() ?? "--",
                d['status'] ?? "N/A",
                d['startDate'] ?? "--",
                d['endDate'] ?? "--",
              ];
            }).toList(),
          ),

          pw.Spacer(),
          pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Text("__________________________", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Warden Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text("GP Chh. Sambhajinagar", style: const pw.TextStyle(fontSize: 9)),
                  ]
              )
          )
        ],
      ));

      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Leave_History_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf'
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate PDF: $e"), backgroundColor: Colors.red),
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allowedIds = userSnapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch = (data['branch'] ?? data['brach'] ?? '')
              .toString()
              .trim();
          return role == 'student' && branch == widget.branchFilter;
        }).map((doc) => doc.id).toSet();

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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _filterDocsForBranch(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (widget.branchFilter == null) {
      return docs;
    }

    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .get();
    final allowedIds = usersSnap.docs.where((doc) {
      final data = doc.data();
      final role = (data['role'] ?? '').toString().toLowerCase();
      final branch =
          (data['branch'] ?? data['brach'] ?? '').toString().trim();
      return role == 'student' && branch == widget.branchFilter;
    }).map((doc) => doc.id).toSet();

    return docs.where((doc) {
      final data = doc.data();
      final studentId =
          (data['studentUid'] ?? data['uid'] ?? data['rollNo']).toString();
      return allowedIds.contains(studentId);
    }).toList();
  }
}
