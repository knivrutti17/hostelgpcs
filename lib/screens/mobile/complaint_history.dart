import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // UPDATED: Consistent session management
import 'package:intl/intl.dart';
import 'dart:convert'; // NEW: Required for Base64 decoding
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  String? _currentRollNo;

  @override
  void initState() {
    super.initState();
    _loadUserRoll();
  }

  // Load Roll No to match filtering in complain.dart
  Future<void> _loadUserRoll() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentRollNo = prefs.getString('user_roll');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text("All Complaints", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.darkTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _currentRollNo == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('studentUid', isEqualTo: _currentRollNo) // Filter by Roll No
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaint history found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    Color statusColor = data['status'] == 'Resolved' ? Colors.green : Colors.blue;
    if (data['status'] == 'Rejected') statusColor = Colors.red;

    String date = data['timestamp'] != null
        ? DateFormat('MMM dd, yyyy').format((data['timestamp'] as Timestamp).toDate())
        : "Recent";

    String? imgStr = data['imageString']; // Fetch Base64 string

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border(left: BorderSide(color: _getUrgencyColor(data['urgency'] ?? "Low"), width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['category'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          // NEW: Display the image proof if it exists
          if (imgStr != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(imgStr.contains(',') ? imgStr.split(',')[1] : imgStr),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Text(data['description'] ?? "", style: const TextStyle(fontSize: 13)),

          // NEW: Display Warden Feedback
          if (data['resolutionText'] != null && data['resolutionText'].toString().isNotEmpty) ...[
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(
                "Warden's Note: ${data['resolutionText']}",
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ),
          ],

          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("To: ${data['sendTo']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 5),
                  Text(data['status'] ?? "Pending", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String level) {
    if (level == "High") return Colors.red;
    if (level == "Medium") return Colors.orange;
    return Colors.green;
  }
}