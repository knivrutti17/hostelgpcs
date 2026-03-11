import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LeavePdfGenerator {
  static Future<void> generateLeavePdf(Map<String, dynamic> studentData, Map<String, dynamic> leaveData) async {
    try {
      final pdf = pw.Document();

      // Load College Logo
      final ByteData logoData = await rootBundle.load('assets/images/gpcslogo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // HEADER SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 60, height: 60),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("GP CHHATRAPATI SAMBHAJINAGAR",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.blue900)),
                          pw.Text("HOSTEL LEAVE PERMISSION SLIP",
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.orange800, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 2, color: PdfColors.blue900),
                  pw.SizedBox(height: 30),

                  // STUDENT SECTION
                  pw.Text("STUDENT DETAILS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  _buildRow("Name", studentData['name'] ?? 'N/A'),
                  _buildRow("Roll Number", studentData['rollNo'] ?? 'N/A'),
                  _buildRow("Department", studentData['department'] ?? 'N/A'),
                  _buildRow("Room Number", studentData['roomNo']?.toString() ?? 'N/A'),

                  pw.SizedBox(height: 30),

                  // LEAVE DETAILS
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Column(
                      children: [
                        _buildRow("Leave Reason", leaveData['reason'] ?? 'N/A'),
                        _buildRow("From Date", leaveData['startDate'] ?? 'N/A'),
                        _buildRow("To Date", leaveData['endDate'] ?? 'N/A'),
                        _buildRow("Current Status", leaveData['status']?.toUpperCase() ?? 'PENDING'),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // SIGNATURE SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text("Student Signature", style: const pw.TextStyle(fontSize: 9)),
                      ]),
                      pw.Column(children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text("Hostel Warden", style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text("This is a system-generated document for GPCS Hostel Portal.",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Leave_Slip_${studentData['rollNo']}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Text(" :  ", style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}