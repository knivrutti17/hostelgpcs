import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:intl/intl.dart';

class RequestLeave extends StatefulWidget {
  const RequestLeave({super.key});

  @override
  State<RequestLeave> createState() => _RequestLeaveState();
}

class _RequestLeaveState extends State<RequestLeave> {
  String? _selectedReason;
  DateTimeRange? _selectedDates;
  bool _isLoading = false;
  String? _currentRollNo; // Store the roll number locally
  final List<String> _reasons = ["Family Function", "Medical Leave", "Going Home", "Other"];

  @override
  void initState() {
    super.initState();
    _loadUserSession(); // Load roll number on start
  }

  // Helper to get Roll No from SharedPreferences
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentRollNo = prefs.getString('user_roll'); // Key from MobileAuthService
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text("Request Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.darkTeal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reason for Leave:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                    decoration: InputDecoration(filled: true, fillColor: AppStyle.bgLightGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 20),
                  const Text("Leave Dates:", style: TextStyle(fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: AppStyle.bgLightGrey, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedDates == null ? "Select Date Range" : "${DateFormat('MMM dd').format(_selectedDates!.start)} - ${DateFormat('MMM dd').format(_selectedDates!.end)}"),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppStyle.darkTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      onPressed: (_isLoading || _currentRollNo == null) ? null : _submitLeave,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Recent Leave Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("View All >", style: TextStyle(color: AppStyle.darkTeal, fontSize: 12))]),
          ),
          Expanded(
            flex: 4,
            child: _currentRollNo == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              // Updated query to use studentUid (Roll Number)
              stream: FirebaseFirestore.instance.collection('leaves')
                  .where('studentUid', isEqualTo: _currentRollNo)
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No recent requests", style: TextStyle(fontSize: 12, color: Colors.grey)));
                return ListView(padding: const EdgeInsets.all(15), children: snapshot.data!.docs.map((doc) => _buildLeaveCard(doc.data() as Map<String, dynamic>)).toList());
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2026, 12, 31));
    if (picked != null) setState(() => _selectedDates = picked);
  }

  Widget _buildLeaveCard(Map<String, dynamic> data) {
    Color statusColor = data['status'] == 'Approved' ? Colors.green : (data['status'] == 'Rejected' ? Colors.red : Colors.orange);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: statusColor, width: 5)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['reason'] ?? "Reason", style: const TextStyle(fontWeight: FontWeight.bold)), Text(data['status'] ?? "Pending", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12))]),
          Text("${data['startDate']} to ${data['endDate']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // UPDATED SUBMIT LOGIC USING ROLL NUMBER
  Future<void> _submitLeave() async {
    if (_selectedReason == null || _selectedDates == null || _currentRollNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a reason and date range")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch student data using the Roll Number as Document ID
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(_currentRollNo).get();

      if (!studentDoc.exists) {
        throw "Student profile not found. Please contact the warden.";
      }

      var sData = studentDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('leaves').add({
        'studentName': sData['name'] ?? 'Unknown',
        'studentUid': _currentRollNo, // Use Roll No as UID for tracking
        'rollNo': _currentRollNo,
        'roomNo': sData['roomNo'] ?? '---',
        'reason': _selectedReason,
        'startDate': DateFormat('MMM dd').format(_selectedDates!.start),
        'endDate': DateFormat('MMM dd').format(_selectedDates!.end),
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Leave Request Submitted Successfully!"), backgroundColor: Colors.green));
        setState(() {
          _selectedReason = null;
          _selectedDates = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}