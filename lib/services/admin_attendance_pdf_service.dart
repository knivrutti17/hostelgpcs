import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const PdfColor _pdfTeal = PdfColor(0.263, 0.541, 0.498);
const PdfColor _pdfTealSoft = PdfColor(0.906, 0.945, 0.937);

class AttendancePdfEntry {
  const AttendancePdfEntry({
    required this.studentName,
    required this.rollNo,
    required this.roomNo,
    required this.status,
    required this.timeOfMarking,
    required this.verificationMethod,
  });

  final String studentName;
  final String rollNo;
  final String roomNo;
  final String status;
  final String timeOfMarking;
  final String verificationMethod;
}

class AdminAttendancePdfService {
  static Future<void> generateDailyReport({
    required DateTime date,
    required String session,
    required List<AttendancePdfEntry> entries,
  }) async {
    final pw.Document pdf = pw.Document();
    final pw.MemoryImage? logo = await _loadLogo();
    final int presentCount = entries.where((entry) => entry.status == 'Present').length;
    final int absentCount = entries.length - presentCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _buildHeader(logo),
          pw.SizedBox(height: 18),
          _buildMetaCard(
            date: date,
            session: session,
            totalStudents: entries.length,
            presentCount: presentCount,
            absentCount: absentCount,
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerDecoration: const pw.BoxDecoration(color: _pdfTeal),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            headers: const [
              'Student Name',
              'Roll No',
              'Room No',
              'Status',
              'Time',
              'Verification',
            ],
            data: entries
                .map(
                  (entry) => [
                    entry.studentName,
                    entry.rollNo,
                    entry.roomNo,
                    entry.status,
                    entry.timeOfMarking,
                    entry.verificationMethod,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          'gpcs_attendance_${DateFormat('yyyy_MM_dd').format(date)}_${session.toLowerCase()}.pdf',
    );
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/gpcslogo.png');
      final Uint8List bytes = data.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _buildHeader(pw.MemoryImage? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _pdfTealSoft,
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Row(
        children: [
          if (logo != null) pw.Image(logo, width: 52, height: 52),
          if (logo != null) pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GPCS HOSTEL PORTAL',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfTeal,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Attendance Dashboard Report',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Government Polytechnic Chhatrapati Sambhajinagar Hostel Administration',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaCard({
    required DateTime date,
    required String session,
    required int totalStudents,
    required int presentCount,
    required int absentCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _metaColumn('Date', DateFormat('dd MMM yyyy').format(date)),
          _metaColumn('Session', session),
          _metaColumn('Total Students', totalStudents.toString()),
          _metaColumn('Present', presentCount.toString()),
          _metaColumn('Absent', absentCount.toString()),
        ],
      ),
    );
  }

  static pw.Widget _metaColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
