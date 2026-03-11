import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:intl/intl.dart';
// Ensure these paths match your project structure
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/leave_pdf_generator.dart';
import 'package:gpcs_hostel_portal/screens/mobile/pdfgenerator/leave_report_generator.dart';

class RequestLeave extends StatefulWidget {
  const RequestLeave({super.key});
  @override
  State<RequestLeave> createState() => _RequestLeaveState();
}

class _RequestLeaveState extends State<RequestLeave> {
  String? _selectedReason;
  DateTimeRange? _selectedDates;
  bool _isLoading = false;
  String? _currentRollNo;
  final List<String> _reasons = ["Family Function", "Medical Leave", "Going Home", "Other"];

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentRollNo = prefs.getString('user_roll'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Request Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF438A7F),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. INPUT FORM SECTION
          _buildInputForm(),
          const Divider(thickness: 1, height: 1),
          // 2. RECENT REQUESTS HEADER
          _buildHistoryHeader(),
          // 3. SCROLLABLE LIST OF REQUESTS
          Expanded(child: _buildRecentLeavesList()),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reason for Leave:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (val) => setState(() => _selectedReason = val),
            decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F7F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
            ),
          ),
          const SizedBox(height: 20),
          const Text("Leave Dates:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(color: const Color(0xFFF5F7F9), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedDates == null
                      ? "Select Date Range"
                      : "${DateFormat('MMM dd').format(_selectedDates!.start)} - ${DateFormat('MMM dd').format(_selectedDates!.end)}"),
                  const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF438A7F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: (_isLoading || _currentRollNo == null) ? null : _submitLeave,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Recent Leave Requests",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
          // Master PDF Icon for Full Report
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF438A7F), size: 26),
            onPressed: _downloadFullReport,
            tooltip: "Download All Requests",
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLeavesList() {
    if (_currentRollNo == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('leaves')
          .where('studentUid', isEqualTo: _currentRollNo)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No requests found", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildLeaveCard(data);
          },
        );
      },
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> data) {
    Color statusColor = data['status'] == 'Approved' ? Colors.green : (data['status'] == 'Rejected' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: statusColor, width: 6))),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['reason'] ?? "Reason", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${data['startDate']} to ${data['endDate']}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(data['status'] ?? "Pending", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  // Individual Download Icon
                  InkWell(
                    onTap: () => _downloadSingleSlip(data),
                    child: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF438A7F), size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LOGIC TO DOWNLOAD ALL
  Future<void> _downloadFullReport() async {
    final studentDoc = await FirebaseFirestore.instance.collection('users').doc(_currentRollNo).get();
    final allLeaves = await FirebaseFirestore.instance.collection('leaves')
        .where('studentUid', isEqualTo: _currentRollNo)
        .orderBy('timestamp', descending: true).get();

    if (studentDoc.exists && allLeaves.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preparing Table Report...")));
      await LeaveReportGenerator.generateAllLeavesTable(studentDoc.data()!, allLeaves.docs);
    }
  }

  // LOGIC TO DOWNLOAD SINGLE SLIP
  Future<void> _downloadSingleSlip(Map<String, dynamic> data) async {
    final studentDoc = await FirebaseFirestore.instance.collection('users').doc(_currentRollNo).get();
    if (studentDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Leave Slip...")));
      await LeavePdfGenerator.generateLeavePdf(studentDoc.data()!, data);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2026, 12, 31));
    if (picked != null) setState(() => _selectedDates = picked);
  }

  Future<void> _submitLeave() async {
    if (_selectedReason == null || _selectedDates == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(_currentRollNo).get();
      var sData = studentDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('leaves').add({
        'studentName': sData['name'],
        'studentUid': _currentRollNo,
        'rollNo': _currentRollNo,
        'department': sData['department'] ?? 'IT',
        'reason': _selectedReason,
        'startDate': DateFormat('MMM dd').format(_selectedDates!.start),
        'endDate': DateFormat('MMM dd').format(_selectedDates!.end),
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() { _selectedReason = null; _selectedDates = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Leave Requested!"), backgroundColor: Colors.green));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}