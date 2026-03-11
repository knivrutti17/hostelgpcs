import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Internal generators
import 'package:gpcs_hostel_portal/utils/receipt_generator.dart';
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/idcard_generate.dart';
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/leave_report_generator.dart';

class DownloadService {
  static Future<void> handleGlobalDownload(BuildContext context, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final String? rollNo = prefs.getString('user_roll');

    if (rollNo == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Generating your $type..."), duration: const Duration(seconds: 1)),
    );

    try {
      // 1. COMPULSORY: Pull personal data from the 'users' collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
      if (!userDoc.exists) return;
      Map<String, dynamic> combinedData = userDoc.data()!;

      if (type == 'Fee Receipt') {
        // 2. COMPULSORY: Pull shared fee data (Same for all students)
        // We fetch the first available receipt to use as a template for everyone
        final sharedReceiptQuery = await FirebaseFirestore.instance
            .collection('fee_receipts')
            .limit(1)
            .get();

        if (sharedReceiptQuery.docs.isNotEmpty) {
          // Merge the shared fee info (Amount, Year) with the student's personal info
          combinedData.addAll(sharedReceiptQuery.docs.first.data());

          // Overwrite ID with a unique one for this student
          combinedData['receiptId'] = "RCPT-$rollNo-${DateTime.now().year}";

          await ReceiptGenerator.generateFeeReceipt(combinedData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Master fee record not found in database."))
          );
        }
      } else if (type == 'ID Card') {
        await IDCardGenerator.generateAndDownloadIDCard(combinedData);
      } else if (type == 'Leave Report') {
        final leaves = await FirebaseFirestore.instance.collection('leaves')
            .where('studentUid', isEqualTo: rollNo).get();
        await LeaveReportGenerator.generateAllLeavesTable(combinedData, leaves.docs);
      }
    } catch (e) {
      debugPrint("Download Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}