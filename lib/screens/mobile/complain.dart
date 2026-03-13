import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
// Ensure this import path is correct based on your project structure
import 'pdfgenerator/complaint_pdf.dart';

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
  bool _isPdfLoading = false;
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

  // FIXED: Corrected named parameter labels to match ComplaintPdfGenerator.generateAndDownload logic
  Future<void> _downloadComplaintReport() async {
    if (_currentRollNo == null) return;

    setState(() => _isPdfLoading = true);
    try {
      // Fetch latest data to ensure PDF is accurate
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('studentUid', isEqualTo: _currentRollNo)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No complaints found to generate report."))
        );
        return;
      }

      // Trigger the external PDF generator logic using NAMED ARGUMENTS
      // Updated to match your specific ComplaintPdfGenerator definition
      await ComplaintPdfGenerator.generateAndDownload(
        docs: snapshot.docs,
        rollNo: _currentRollNo!,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
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
        base64ImageString = base64Encode(imageBytes);
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
        setState(() {
          _selectedCategory = null;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Uint8List? _safeDecode(String? imgStr) {
    if (imgStr == null || imgStr.isEmpty) return null;
    try {
      String cleanBase64 = imgStr.contains(',') ? imgStr.split(',')[1] : imgStr;
      return base64Decode(cleanBase64.trim());
    } catch (e) {
      debugPrint("Decode Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text("Register Complaint", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.darkTeal,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isLoading || _isPdfLoading)
            const LinearProgressIndicator(color: Colors.orangeAccent),
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
                      ElevatedButton.icon(
                        onPressed: _isPdfLoading ? null : _downloadComplaintReport,
                        icon: _isPdfLoading
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                        label: Text(_isPdfLoading ? "GENERATING..." : "DOWNLOAD REPORT", style: const TextStyle(color: Colors.white, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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

  Widget _toggle(String title, List<String> opts, String cur, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No complaints found.", style: TextStyle(color: Colors.grey))));

        final displayDocs = snapshot.data!.docs.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayDocs.length,
          itemBuilder: (context, index) {
            var data = displayDocs[index].data() as Map<String, dynamic>;
            Color statusColor = data['status'] == 'Resolved' ? Colors.green : Colors.orange;
            Uint8List? imageBytes = _safeDecode(data['imageString']);

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
                leading: (imageBytes != null)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover),
                )
                    : const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.build, color: Colors.blue)),
                title: Text(data['category'] ?? "General", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(data['description'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: Text(data['status']?.toUpperCase() ?? "PENDING", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            );
          },
        );
      },
    );
  }
}