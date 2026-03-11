import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveReportGenerator {
  static Future<void> generateAllLeavesTable(Map<String, dynamic> studentData, List<QueryDocumentSnapshot> leaves) async {
    final pdf = pw.Document();

    // Load Logo for Header
    final ByteData logoData = await rootBundle.load('assets/images/gpcslogo.png');
    final pw.MemoryImage logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 40, height: 40),
                pw.Text("LEAVE HISTORY REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ],
            ),
            pw.Divider(thickness: 1),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Text("Student Name: ${studentData['name']}"),
          pw.Text("Roll Number: ${studentData['rollNo']}"),
          pw.SizedBox(height: 20),
          // Professional Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
            headers: ['Reason', 'Start Date', 'End Date', 'Status'],
            data: leaves.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return [d['reason'], d['startDate'], d['endDate'], d['status']];
            }).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}