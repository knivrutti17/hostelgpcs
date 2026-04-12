import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LeaveModel {
  const LeaveModel({
    required this.studentName,
    required this.room,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  final String studentName;
  final String room;
  final String status;
  final String startDate;
  final String endDate;
}

class LeaveReportGenerator {
  static Future<List<LeaveModel>> buildLeaveModelsWithRooms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> leaveDocs,
  ) async {
    return Future.wait(leaveDocs.map((doc) async {
      final leaveData = doc.data();
      final userData = await _userDataForLeave(leaveData);
      final roomNo = userData?['roomNo']?.toString() ??
          leaveData['roomNo']?.toString() ??
          "--";

      return LeaveModel(
        studentName: leaveData['studentName']?.toString() ??
            userData?['name']?.toString() ??
            "N/A",
        room: roomNo,
        status: leaveData['status']?.toString() ?? "N/A",
        startDate: leaveData['startDate']?.toString() ?? "--",
        endDate: leaveData['endDate']?.toString() ?? "--",
      );
    }));
  }

  static Future<Uint8List> generateLeavePdf(
    List<LeaveModel> leaves,
    Uint8List logoBytes,
    Uint8List watermarkBytes,
  ) async {
    final pdf = pw.Document();
    final logoImage = pw.MemoryImage(logoBytes);
    final watermarkImage = pw.MemoryImage(watermarkBytes);
    const darkBlue = PdfColor.fromInt(0xFF0B3D78);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(),
          buildBackground: (context) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: darkBlue, width: 1.2),
                  ),
                ),
              ),
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.15,
                  child: pw.Image(watermarkImage, width: 330, height: 330),
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          _letterhead(logoImage, darkBlue),
          pw.SizedBox(height: 18),
          pw.Center(
            child: pw.Text(
              "Official Leave History Report",
              style: pw.TextStyle(
                color: darkBlue,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              "Generated on: ${_generatedOn()}",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 18),
          _leaveTable(leaves, darkBlue),
          pw.Spacer(),
          pw.Divider(color: darkBlue, thickness: 0.8),
          pw.Center(
            child: pw.Text(
              "GOVERNMENT POLYTECHNIC, CHATRAPATI SAMBHAJI NAGAR",
              style: pw.TextStyle(
                color: darkBlue,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Map<String, dynamic>?> _userDataForLeave(
    Map<String, dynamic> leaveData,
  ) async {
    final studentId = (leaveData['studentUid'] ??
            leaveData['uid'] ??
            leaveData['rollNo'] ??
            '')
        .toString();

    if (studentId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    }

    final rollNo = (leaveData['rollNo'] ?? '').toString();
    if (rollNo.isEmpty) return null;

    final usersByRoll = await FirebaseFirestore.instance
        .collection('users')
        .where('rollNo', isEqualTo: rollNo)
        .limit(1)
        .get();

    if (usersByRoll.docs.isEmpty) return null;
    return usersByRoll.docs.first.data();
  }

  static Future<void> generateAllLeavesTable(
    Map<String, dynamic> studentData,
    List<QueryDocumentSnapshot> leaves,
  ) async {
    final logoData = await rootBundle.load('assets/images/gpcslogo.png');
    final logoBytes = logoData.buffer.asUint8List();
    final studentRoom = studentData['roomNo']?.toString() ?? "--";
    final leaveModels = leaves.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return LeaveModel(
        studentName: studentData['name']?.toString() ?? "N/A",
        room: studentRoom,
        status: data['status']?.toString() ?? "Pending",
        startDate: data['startDate']?.toString() ?? "--",
        endDate: data['endDate']?.toString() ?? "--",
      );
    }).toList();

    final bytes = await generateLeavePdf(leaveModels, logoBytes, logoBytes);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Leave_History_${studentData['rollNo'] ?? 'Student'}.pdf',
    );
  }

  static pw.Widget _letterhead(pw.MemoryImage logoImage, PdfColor darkBlue) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logoImage, width: 60, height: 60),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "GOVERNMENT POLYTECHNIC, CHATRAPATI SAMBHAJI NAGAR",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: darkBlue,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Osmanpura, Chhatrapati Sambhaji Nagar, Maharashtra",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "Contact: 0240-2334724",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: darkBlue, width: 0.8),
          ),
          child: pw.Center(
            child: pw.Text(
              "Website: www.gpaurangabad.ac.in   |   Email: office.gpcsambhajinagar@dtemaharashtra.gov.in",
              style: pw.TextStyle(
                color: darkBlue,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _leaveTable(List<LeaveModel> leaves, PdfColor darkBlue) {
    const columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.2),
      1: pw.FlexColumnWidth(0.8),
      2: pw.FlexColumnWidth(1.1),
      3: pw.FlexColumnWidth(1.1),
      4: pw.FlexColumnWidth(1.1),
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: darkBlue),
          children: [
            _headerCell("Student Name"),
            _headerCell("Room"),
            _headerCell("Status"),
            _headerCell("Start Date"),
            _headerCell("End Date"),
          ],
        ),
        ...leaves.asMap().entries.map((entry) {
          final index = entry.key;
          final leave = entry.value;
          final rowColor = index.isEven
              ? PdfColors.white
              : const PdfColor.fromInt(0xFFEFF5FB);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _dataCell(leave.studentName),
              _dataCell(leave.room),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: _statusBadge(leave.status),
              ),
              _dataCell(leave.startDate),
              _dataCell(leave.endDate),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final color = normalized == 'rejected'
        ? PdfColors.red700
        : normalized == 'approved'
            ? PdfColors.green700
            : PdfColors.orange700;

    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          status,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static String _generatedOn() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return "${twoDigits(now.day)}-${twoDigits(now.month)}-${now.year} "
        "${twoDigits(now.hour)}:${twoDigits(now.minute)}";
  }
}
