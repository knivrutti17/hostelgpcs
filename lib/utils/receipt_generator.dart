import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptGenerator {
  /// Generates an A4 PDF receipt using hybrid data from 'users' and 'fee_receipts'
  static Future<void> generateFeeReceipt(Map<String, dynamic> combinedData) async {
    final pdf = pw.Document();

    // 1. Asset Loading: Fetch the official hostel logo from assets
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    // 2. Data Mapping from Firestore Collections
    final String rollNo = combinedData['rollNo'] ?? 'N/A';

    // Use the stored Receipt ID from the database
    final String receiptId = combinedData['receiptId'] ?? "GH-2026-$rollNo";

    // Parse the stored Payment Date instead of using DateTime.now()
    String dateStr = "N/A";
    if (combinedData['paymentDate'] != null) {
      DateTime dt = (combinedData['paymentDate'] as Timestamp).toDate();
      dateStr = DateFormat('dd/MM/yyyy').format(dt);
    }

    // Secure verification URL pointing to the Web Portal
    final String verifyUrl = "https://gpcs-portal.web.app/verify?id=$receiptId";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange800, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER SECTION: Government Branding
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, width: 70, height: 70),
                    pw.Column(
                      children: [
                        pw.Text("GPCS GOVERNMENT HOSTEL",
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text("(Government Hostel — Maharashtra State)", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("Osmanpura, Chhatrapati Sambhajinagar", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(width: 70),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.orange),
                pw.Center(child: pw.Text("HOSTEL ANNUAL FEE RECEIPT",
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Receipt No: $receiptId", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text("Date: $dateStr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 20),

                // STUDENT DATA: Pulled from 'users' collection
                _buildInfoTable("Student Details", [
                  ["Name", combinedData['name'] ?? "Unknown"],
                  ["Roll Number", rollNo],
                  ["Category", combinedData['category'] ?? "Open"],
                  ["Room Number", combinedData['roomNo'] ?? "N/A"],
                  ["Mobile", combinedData['contact'] ?? "N/A"],
                ]),

                pw.SizedBox(height: 20),

                // PAYMENT DATA: Pulled from 'fee_receipts' collection
                _buildInfoTable("Payment Details", [
                  ["Fee Type", "Annual Hostel Fee"],
                  ["Amount Paid", "INR ${combinedData['amount'] ?? '1800'}"],
                  ["Payment Mode", "CASH"],
                  ["Academic Year", combinedData['academicYear'] ?? "2025-26"],
                  ["Payment Status", combinedData['status'] ?? "PAID"],
                ]),

                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.grey100,
                  child: pw.Text(
                    "Received with thanks from the above student the sum of INR 1800 (Rupees One Thousand Eight Hundred Only) towards Annual Government Hostel Fee for the Academic Year ${combinedData['academicYear'] ?? '2025-26'}.",
                    style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center,
                  ),
                ),

                pw.Spacer(),

                // QR VERIFICATION & SIGNATURES
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        // Dynamic QR points to the Web Portal for verification
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: verifyUrl,
                          width: 80, height: 80,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text("Scan to Verify", style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("____________________"),
                        pw.Text("Warden Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text("This is a computer-generated receipt.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
              ],
            ),
          );
        },
      ),
    );

    // Save and preview the PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildInfoTable(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange900, fontSize: 11)),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: rows.map((row) => pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(row[0], style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(row[1], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            ],
          )).toList(),
        ),
      ],
    );
  }
}