import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintPdfGenerator {
  // FIXED: Method signature now matches the call from complain.dart
  static Future<void> generateAndDownload({
    required List<QueryDocumentSnapshot> docs,
    required String rollNo,
  }) async {
    final pdf = pw.Document();

    // Load College Logo from assets
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/gpcslogo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      // Logo fail fallback
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (pw.Context context) => _buildProfessionalHeader(logoImage),
        footer: (pw.Context context) => _buildProfessionalFooter(context),
        build: (pw.Context context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Student Enrollment: $rollNo",
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text("Academic Year: 2024-25",
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "OFFICIAL COMPLAINT LODGED RECORDS",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 15),

          // PROFESSIONAL DATA TABLE
          pw.TableHelper.fromTextArray(
            headers: ["#", "Category", "Description", "Urgency", "Status"],
            data: List<List<dynamic>>.generate(
              docs.length,
                  (index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return [
                  (index + 1).toString(),
                  data['category'] ?? "General",
                  data['description'] ?? "N/A",
                  data['urgency'] ?? "Normal",
                  data['status']?.toUpperCase() ?? "PENDING",
                ];
              },
            ),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
            cellHeight: 35,
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FixedColumnWidth(100),
              2: const pw.FlexColumnWidth(),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FixedColumnWidth(70),
            },
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),

          pw.SizedBox(height: 50),

          // SIGNATURE SECTION
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(width: 120, child: pw.Divider(thickness: 1)),
                      pw.Text("Student Signature", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 30),
                      pw.SizedBox(width: 120, child: pw.Divider(thickness: 1)),
                      pw.Text("Warden Signature", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                )
              ]
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildProfessionalHeader(pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) pw.Image(logo, width: 60, height: 60),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("GOVERNMENT POLYTECHNIC, CHHATRAPATI SAMBHAJINAGAR",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
                  pw.Text("HOSTEL PORTAL MANAGEMENT SYSTEM",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.teal900)),
                  pw.Text("Official Complaint History Report",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1.5, color: PdfColors.teal900),
      ],
    );
  }

  static pw.Widget _buildProfessionalFooter(pw.Context context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Generated via GPCS Hostel App",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text("Report Date: $dateStr",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text("Page ${context.pageNumber} of ${context.pagesCount}",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }
}