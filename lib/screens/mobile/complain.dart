import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  String? _currentRollNo;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Stream<QuerySnapshot>? _complaintStream;

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
    _initSessionAndStream();
  }

  Future<void> _initSessionAndStream() async {
    final prefs = await SharedPreferences.getInstance();
    final rollNo = prefs.getString('user_roll');

    setState(() {
      _currentRollNo = rollNo;
      if (_currentRollNo != null) {
        _complaintStream = FirebaseFirestore.instance
            .collection('complaints')
            .where('studentUid', isEqualTo: _currentRollNo)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .snapshots();
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final String targetPath = pickedFile.path.replaceAll(".jpg", "_compressed.jpg");
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 35,
        minWidth: 400,
      );

      if (compressedFile != null) {
        setState(() => _selectedImage = File(compressedFile.path));
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null || _descriptionController.text.isEmpty || _currentRollNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? base64ImageString;
      if (_selectedImage != null) {
        List<int> imageBytes = await _selectedImage!.readAsBytes();
        base64ImageString = 'data:image/jpeg;base64,' + base64Encode(imageBytes);
      }

      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(_currentRollNo!).get();
      if (!studentDoc.exists) throw "Hostel record not found.";

      var studentData = studentDoc.data() as Map<String, dynamic>;

      String complaintId = "${_currentRollNo}_${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance.collection('complaints').doc(complaintId).set({
        'studentName': studentData['name'] ?? 'Unknown',
        'rollNo': _currentRollNo,
        'roomNo': studentData['roomNo'] ?? '---',
        'studentUid': _currentRollNo,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'urgency': _urgency,
        'sendTo': _sendTo,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'imageString': base64ImageString,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint Registered!"), backgroundColor: Colors.green));
        _descriptionController.clear();
        setState(() { _selectedCategory = null; _selectedImage = null; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text("Register Complaint", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.darkTeal,
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(color: AppStyle.darkTeal),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("What is the issue?", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true, fillColor: AppStyle.bgLightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Describe the problem...",
                      filled: true, fillColor: AppStyle.bgLightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Photo Proof:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120, width: double.infinity,
                      decoration: BoxDecoration(color: AppStyle.bgLightGrey, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: _selectedImage == null
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.grey), Text("Tap to capture photo", style: TextStyle(color: Colors.grey, fontSize: 12))])
                          : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FIXED: Changed from Row to Column to prevent 13px Right Overflow
                  _toggle("Urgency:", ["Low", "Medium", "High"], _urgency, (v) => setState(() => _urgency = v)),
                  const SizedBox(height: 15),
                  _toggle("Send to:", ["Warden", "HOD"], _sendTo, (v) => setState(() => _sendTo = v)),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppStyle.darkTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: (_isLoading || _currentRollNo == null) ? null : _submitComplaint,
                      child: const Text("SUBMIT COMPLAINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Complaints", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/complaint_history'),
                        child: const Text("View All", style: TextStyle(color: AppStyle.darkTeal, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildRecentList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED TOGGLE: Now takes full width of the parent for better UI alignment
  Widget _toggle(String title, List<String> opts, String cur, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap( // Using Wrap instead of Row for extra safety against overflow
          spacing: 8.0,
          children: opts.map((o) => ChoiceChip(
            label: Text(o, style: TextStyle(fontSize: 11, color: cur == o ? Colors.white : Colors.black)),
            selected: cur == o,
            selectedColor: AppStyle.darkTeal,
            onSelected: (s) => onSel(o),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildRecentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _complaintStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

            Color statusColor = Colors.orange;
            Color statusBg = Colors.orange.withOpacity(0.1);

            if (data['status'] == 'Resolved') {
              statusColor = Colors.green;
              statusBg = Colors.green.withOpacity(0.1);
            } else if (data['status'] == 'Rejected') {
              statusColor = Colors.red;
              statusBg = Colors.red.withOpacity(0.1);
            }

            String? imgStr = data['imageString'];

            return Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  border: Border(left: BorderSide(color: statusColor, width: 5))
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: imgStr != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(imgStr.contains(',') ? imgStr.split(',')[1] : imgStr),
                    width: 50, height: 50, fit: BoxFit.cover,
                  ),
                )
                    : const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.build, color: Colors.blue)),
                title: Text(data['category'] ?? "General", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(data['description'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    if (data['resolutionText'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Note: ${data['resolutionText']}",
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data['timestamp'] != null ? DateFormat('MMM dd').format((data['timestamp'] as Timestamp).toDate()) : "Recent",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['status']?.toUpperCase() ?? "PENDING",
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}