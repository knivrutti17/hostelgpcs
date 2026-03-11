import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class IDCardGenerator {

  static Future<void> generateAndDownloadIDCard(
      Map<String, dynamic> data) async {

    final pdf = pw.Document();

    final ByteData logoData =
    await rootBundle.load('assets/images/gpcslogo.png');

    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    pw.MemoryImage? profileImage;

    if (data['photoUrl'] != null &&
        data['photoUrl'].toString().isNotEmpty) {
      try {
        final Uint8List decodedBytes = base64Decode(data['photoUrl']);
        profileImage = pw.MemoryImage(decodedBytes);
      } catch (e) {
        debugPrint("Photo decode error $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {

          return pw.Center(
            child: pw.Container(
              width: 110 * PdfPageFormat.mm,
              height: 65 * PdfPageFormat.mm,

              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),

              child: pw.Column(
                children: [

                  /// BLUE HEADER
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [
                          PdfColors.blue900,
                          PdfColors.blue600
                        ],
                      ),
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),

                    child: pw.Row(
                      children: [

                        pw.Image(logoImage, width: 26),

                        pw.SizedBox(width: 6),

                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [

                            pw.Text(
                              "Government Polytechnic, Chhatrapati Sambhajinagar",
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            pw.Text(
                              "(An Autonomous Institute of Govt. of Maharashtra)",
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 6,
                              ),
                            ),

                            pw.Text(
                              "Osmanpura, Station Road, Chhatrapati Sambhajinagar",
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 6,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  /// BODY
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),

                      decoration: const pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          colors: [
                            PdfColors.amber50,
                            PdfColors.amber100
                          ],
                        ),
                      ),

                      child: pw.Stack(
                        children: [

                          /// WATERMARK
                          pw.Center(
                            child: pw.Opacity(
                              opacity: 0.05,
                              child: pw.Image(
                                logoImage,
                                width: 80,
                              ),
                            ),
                          ),

                          /// CONTENT
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [

                              pw.Row(
                                mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                                children: [

                                  pw.Text(
                                    "Boys Hostel Identity Card",
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),

                                  pw.Text(
                                    "Enrollment No : ${data['rollNo']}",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red,
                                    ),
                                  ),
                                ],
                              ),

                              pw.SizedBox(height: 6),

                              pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [

                                  /// PHOTO WITH STYLISH CORNERS + SIDE COLOR
                                  pw.Container(
                                    decoration: pw.BoxDecoration(
                                      borderRadius:
                                      pw.BorderRadius.circular(6),
                                      border: pw.Border.all(
                                          color: PdfColors.blue700,
                                          width: 2),
                                    ),

                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.all(2),

                                      decoration: const pw.BoxDecoration(
                                        color: PdfColors.blue50,
                                        borderRadius:
                                        pw.BorderRadius.all(
                                            pw.Radius.circular(6)),
                                      ),

                                      child: pw.ClipRRect(
                                        horizontalRadius: 6,
                                        verticalRadius: 6,
                                        child: pw.Container(
                                          width: 26 * PdfPageFormat.mm,
                                          height: 32 * PdfPageFormat.mm,

                                          child: profileImage != null
                                              ? pw.Image(
                                            profileImage,
                                            fit: pw.BoxFit.cover,
                                          )
                                              : pw.Center(
                                            child: pw.Text(
                                              "PHOTO",
                                              style: pw.TextStyle(
                                                  fontSize: 6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  pw.SizedBox(width: 10),

                                  /// DETAILS
                                  pw.Expanded(
                                    child: pw.Column(
                                      children: [

                                        _row("Name", data['name'] ?? "N/A"),

                                        _row("Programme",
                                            data['department'] ??
                                                "Information Technology"),

                                        _row("Date of Birth",
                                            data['dob'] ?? "N/A"),

                                        _row("Contact No",
                                            data['contact'] ?? "N/A"),

                                        _row("Address",
                                            data['address'] ?? "N/A"),
                                      ],
                                    ),
                                  )
                                ],
                              ),

                              pw.Spacer(),

                              pw.Row(
                                mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                                children: [

                                  pw.Text(
                                    "Principal",
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),

                                  pw.Text(
                                    "GP Boys Hostel",
                                    style: pw.TextStyle(fontSize: 7),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Hostel_ID_${data['rollNo']}.pdf",
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),

      child: pw.Row(
        children: [

          pw.SizedBox(
            width: 60,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),

          pw.Text(" : ", style: const pw.TextStyle(fontSize: 8)),

          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}