import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:intl/intl.dart';

class RegisterComplaint extends StatefulWidget {
  const RegisterComplaint({super.key});

  @override
  State<RegisterComplaint> createState() => _RegisterComplaintState();
}

class _RegisterComplaintState extends State<RegisterComplaint> {
  String? _selectedCategory;
  String _urgency = "High";
  String _sendTo = "Warden";
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // Stable stream variable to prevent UI blinking
  late Stream<QuerySnapshot> _complaintStream;

  final List<String> _categories = [
    "Electrical (Fan, Light, Switch)",
    "Plumbing (Tap, Leakage, Toilet)",
    "Furniture (Bed, Table, Cupboard)",
    "Cleaning/Janitor",
    "Internet/WiFi",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // Initializing the stream with sorting enabled
    // Ensure you have created the Firestore Index for this to work
    _complaintStream = FirebaseFirestore.instance
        .collection('complaints')
        .where('studentUid', isEqualTo: user?.uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text("Register Complaint",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.darkTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/complaint_history'),
            icon: const Icon(Icons.history, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // TOP SECTION: Form (Scrollable to prevent 18px overflow)
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const Text("What is the issue?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: "Select Category",
                        filled: true,
                        fillColor: AppStyle.bgLightGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Describe the problem...",
                        filled: true,
                        fillColor: AppStyle.bgLightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToggleSection("Urgency:", ["Low", "Medium", "High"], _urgency, (val) => setState(() => _urgency = val)),
                        _buildToggleSection("Send to:", ["Warden", "HOD"], _sendTo, (val) => setState(() => _sendTo = val)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyle.darkTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: _isLoading ? null : _submitComplaint,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("SUBMIT COMPLAINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MIDDLE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Complaints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/complaint_history'),
                        child: const Text("View All", style: TextStyle(color: AppStyle.darkTeal, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),

            // BOTTOM SECTION: Live Complaint List
            Expanded(
              flex: 4,
              child: StreamBuilder<QuerySnapshot>(
                stream: _complaintStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No recent complaints.", style: TextStyle(color: Colors.grey, fontSize: 12)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildComplaintCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection(String title, List<String> options, String current, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 5),
        Row(
          children: options.map((opt) {
            bool isSelected = current == opt;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text(opt, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                selected: isSelected,
                selectedColor: AppStyle.darkTeal,
                onSelected: (s) => onSelect(opt),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> data) {
    Color statusColor = data['status'] == 'Resolved' ? Colors.green : Colors.blue;
    String date = data['timestamp'] != null
        ? DateFormat('MMM dd').format((data['timestamp'] as Timestamp).toDate())
        : "Recent";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: _getUrgencyColor(data['urgency'] ?? "Low"), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(data['description'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("To: ${data['sendTo']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Row(
                children: [
                  Icon(data['status'] == 'Resolved' ? Icons.check_circle : Icons.sync, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(data['status'] ?? "Pending", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
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

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      var studentData = studentDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('complaints').add({
        'studentName': studentData['name'] ?? 'Unknown',
        'rollNo': studentData['rollNo'] ?? '---',
        'roomNo': studentData['roomNo'] ?? '---',
        'studentUid': user.uid,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'urgency': _urgency,
        'sendTo': _sendTo,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint Submitted!")));
        _descriptionController.clear();
        setState(() => _selectedCategory = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}