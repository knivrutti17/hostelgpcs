import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:gpcs_hostel_portal/utils/receipt_generator.dart';

class StudentFees extends StatefulWidget {
  const StudentFees({super.key});

  @override
  State<StudentFees> createState() => _StudentFeesState();
}

class _StudentFeesState extends State<StudentFees> {
  bool _isDownloading = false; // Controls the loading animation

  Future<Map<String, dynamic>?> _fetchCombinedFeeData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rollNo = prefs.getString('user_roll');
    if (rollNo == null) return null;

    var userDoc = await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
    var receiptQuery = await FirebaseFirestore.instance
        .collection('fee_receipts')
        .where('rollNo', isEqualTo: rollNo)
        .limit(1)
        .get();

    if (!userDoc.exists) return null;
    Map<String, dynamic> combined = userDoc.data()!;
    if (receiptQuery.docs.isNotEmpty) {
      combined.addAll(receiptQuery.docs.first.data());
    }
    return combined;
  }

  // Real-load simulation for professional feel
  Future<void> _handleDownload(Map<String, dynamic> data) async {
    setState(() => _isDownloading = true);

    try {
      // Simulate a small delay for a "real loading" effect
      await Future.delayed(const Duration(milliseconds: 1500));
      await ReceiptGenerator.generateFeeReceipt(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating receipt: $e"))
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<Map<String, dynamic>?>(
          future: _fetchCombinedFeeData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppStyle.primaryTeal)));
            }

            final data = snapshot.data;
            final bool isPaid = data?['feesPaid'] ?? false;

            return Scaffold(
              backgroundColor: AppStyle.bgWhite,
              appBar: AppBar(
                title: const Text("Hostel Fees", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AppStyle.darkTeal,
                elevation: 0,
              ),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildStatusCard(isPaid),
                    const SizedBox(height: 20),
                    if (isPaid && data != null) _buildTransactionDetails(data, context),
                    if (!isPaid) _buildUnpaidMessage(),
                  ],
                ),
              ),
            );
          },
        ),

        // Professional Loading Overlay
        if (_isDownloading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  const Text("Processing Receipt...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // (Keep _buildStatusCard, _dataRow, and _buildUnpaidMessage logic from your provided code)

  Widget _buildTransactionDetails(Map<String, dynamic> data, BuildContext context) {
    String date = "N/A";
    if (data['paymentDate'] != null) {
      date = DateFormat('dd MMM yyyy').format((data['paymentDate'] as Timestamp).toDate());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppStyle.cardDecoration,
          child: Column(
            children: [
              _dataRow("Receipt ID", data['receiptId'] ?? "N/A"),
              _dataRow("Amount", "₹${data['amount'] ?? '1800'}"),
              _dataRow("Date", date),
              _dataRow("Academic Year", data['academicYear'] ?? "2025-26"),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.darkTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
            ),
            onPressed: _isDownloading ? null : () => _handleDownload(data),
            icon: const Icon(Icons.file_download, color: Colors.white),
            label: const Text("DOWNLOAD RECEIPT (PDF)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isPaid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Payment Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPaid ? "PAID" : "UNPAID",
              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUnpaidMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 50),
        child: Text(
          "No payment records found.\nPlease contact the Warden to pay your annual fee of ₹1800.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}