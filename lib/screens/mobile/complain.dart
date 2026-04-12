import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdfgenerator/complaint_pdf.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String base64Image;

  const FullScreenImageViewer({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 56,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RegisterComplaint extends StatefulWidget {
  const RegisterComplaint({super.key});

  @override
  State<RegisterComplaint> createState() => _RegisterComplaintState();
}

class _RegisterComplaintState extends State<RegisterComplaint> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final Set<String> _resolvingIds = {};

  final List<String> _categories = const [
    'Electrical (Fan, Light, Switch)',
    'Plumbing (Tap, Leakage, Toilet)',
    'Furniture (Bed, Table, Cupboard)',
    'Cleaning/Janitor',
    'Internet/WiFi',
    'Other',
  ];

  String? _selectedCategory;
  String _urgency = 'High';
  String _sendTo = 'Warden';
  String? _rollNo;
  File? _selectedIssueImage;
  bool _isSubmitting = false;
  bool _isPdfLoading = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _complaintStream;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rollNo = prefs.getString('user_roll');
    if (!mounted) return;

    setState(() {
      _rollNo = rollNo;
      if (rollNo != null) {
        _complaintStream = FirebaseFirestore.instance
            .collection('complaints')
            .where('studentUid', isEqualTo: rollNo)
            .snapshots();
      }
    });
  }

  Future<File?> _pickCompressedImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (pickedFile == null) return null;

    final targetPath =
        '${pickedFile.path.replaceAll(RegExp(r'\.\w+$'), '')}_compressed.jpg';
    final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      targetPath,
      quality: 55,
      minWidth: 720,
    );

    return File((compressedFile ?? pickedFile).path);
  }

  Future<String> _fileToBase64(File file) async {
    final bytes = await XFile(file.path).readAsBytes();
    return base64Encode(bytes);
  }

  String _normalizeBranch(String rawBranch) {
    final branch = rawBranch.trim();
    final lower = branch.toLowerCase();
    if (lower == 'it' || lower == 'information technology') {
      return 'Information technology';
    }
    return branch.isEmpty ? 'Unknown' : branch;
  }

  String _issueBase64(Map<String, dynamic> data) {
    return (data['issuePhotoBase64'] ?? data['imageString'] ?? '').toString();
  }

  String _resolutionBase64(Map<String, dynamic> data) {
    return (data['resolutionPhotoBase64'] ?? '').toString();
  }

  String _adminMessage(Map<String, dynamic> data) {
    return (data['adminMessage'] ?? data['resolutionText'] ?? '').toString();
  }

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null ||
        _descriptionController.text.trim().isEmpty ||
        _rollNo == null ||
        _selectedIssueImage == null) {
      _showSnackBar(
        'Please complete the form and capture the issue photo.',
        Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_rollNo)
          .get();
      final studentData = studentDoc.data() ?? <String, dynamic>{};
      final complaintId = '${_rollNo}_${DateTime.now().millisecondsSinceEpoch}';
      final issuePhotoBase64 = await _fileToBase64(_selectedIssueImage!);

      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .set({
        'studentName': studentData['name'] ?? 'Unknown',
        'rollNo': _rollNo,
        'roomNo': studentData['roomNo'] ?? '---',
        'studentUid': _rollNo,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'urgency': _urgency,
        'sendTo': _sendTo,
        'branch': _normalizeBranch(
          (studentData['branch'] ??
                  studentData['department'] ??
                  studentData['brach'] ??
                  '')
              .toString(),
        ),
        'issuePhotoBase64': issuePhotoBase64,
        'adminMessage': '',
        'resolutionPhotoBase64': '',
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedIssueImage = null;
        _urgency = 'High';
        _sendTo = 'Warden';
      });
      _showSnackBar('Complaint registered.', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resolveComplaint(String complaintId) async {
    if (_resolvingIds.contains(complaintId)) return;

    final cleanPhoto = await _pickCompressedImage();
    if (cleanPhoto == null || !mounted) return;

    setState(() => _resolvingIds.add(complaintId));
    try {
      final resolutionPhotoBase64 = await _fileToBase64(cleanPhoto);
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'resolutionPhotoBase64': resolutionPhotoBase64,
        'status': 'Resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnackBar('Complaint marked Resolved.', Colors.green);
    } catch (e) {
      _showSnackBar('Resolve failed: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _resolvingIds.remove(complaintId));
      }
    }
  }

  Future<void> _downloadComplaintReport() async {
    if (_rollNo == null) return;

    setState(() => _isPdfLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('studentUid', isEqualTo: _rollNo)
          .get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) => _timestampValue(b.data()).compareTo(
              _timestampValue(a.data()),
            ));

      if (docs.isEmpty) {
        _showSnackBar(
          'No complaints found to generate report.',
          Colors.orange,
        );
        return;
      }

      await ComplaintPdfGenerator.generateAndDownload(
        docs: docs,
        rollNo: _rollNo!,
      );
    } catch (e) {
      _showSnackBar('PDF Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isPdfLoading = false);
      }
    }
  }

  int _timestampValue(Map<String, dynamic> data) {
    final value = data['timestamp'];
    return value is Timestamp ? value.millisecondsSinceEpoch : 0;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showSnackBar(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bgWhite,
      appBar: AppBar(
        title: const Text(
          'Register Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppStyle.darkTeal,
      ),
      body: Column(
        children: [
          if (_isSubmitting || _isPdfLoading)
            const LinearProgressIndicator(color: Colors.orangeAccent),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What is the issue?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppStyle.bgLightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe the problem...',
                      filled: true,
                      fillColor: AppStyle.bgLightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Issue Photo Proof',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final image = await _pickCompressedImage();
                      if (image != null && mounted) {
                        setState(() => _selectedIssueImage = image);
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppStyle.bgLightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _selectedIssueImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to capture issue evidence',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedIssueImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Before-photo evidence is required.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _buildToggle(
                    'Urgency:',
                    ['Low', 'Medium', 'High'],
                    _urgency,
                    (value) => setState(() => _urgency = value),
                  ),
                  const SizedBox(height: 15),
                  _buildToggle(
                    'Send to:',
                    ['Warden', 'HOD'],
                    _sendTo,
                    (value) => setState(() => _sendTo = value),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || _rollNo == null)
                          ? null
                          : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.darkTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SUBMIT COMPLAINT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Complaints',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            _isPdfLoading ? null : _downloadComplaintReport,
                        icon: _isPdfLoading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf,
                                size: 16,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isPdfLoading ? 'GENERATING...' : 'DOWNLOAD REPORT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildComplaintList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options
              .map(
                (option) => ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      fontSize: 11,
                      color: current == option ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: current == option,
                  selectedColor: AppStyle.darkTeal,
                  onSelected: (_) => onTap(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildComplaintList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _complaintStream,
      builder: (context, snapshot) {
        if (_rollNo == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = (snapshot.data?.docs ?? []).toList()
          ..sort((a, b) => _timestampValue(b.data()).compareTo(
                _timestampValue(a.data()),
              ));

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final visibleDocs = docs.take(5).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleDocs.length,
          itemBuilder: (context, index) => _buildComplaintCard(
              visibleDocs[index].id, visibleDocs[index].data()),
        );
      },
    );
  }

  Widget _buildComplaintCard(String complaintId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Pending').toString();
    final issuePhotoBase64 = _issueBase64(data);
    final resolutionPhotoBase64 = _resolutionBase64(data);
    final adminMessage = _adminMessage(data);
    final isResolving = _resolvingIds.contains(complaintId);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
        border: Border(
          left: BorderSide(color: _statusColor(status), width: 5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (data['category'] ?? 'General').toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (data['description'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              _statusBadge(status, _statusColor(status)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusBadge(
                (data['urgency'] ?? 'Low').toString(),
                _urgencyColor((data['urgency'] ?? 'Low').toString()),
              ),
              _statusBadge(
                  (data['sendTo'] ?? 'Warden').toString(), Colors.teal),
              _statusBadge(
                data['timestamp'] is Timestamp
                    ? DateFormat('dd MMM, hh:mm a')
                        .format((data['timestamp'] as Timestamp).toDate())
                    : 'Recent',
                Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status != 'Resolved') ...[
            _photoPanel('Issue Proof', issuePhotoBase64, 180),
            const SizedBox(height: 12),
          ],
          if (status == 'Pending')
            _messagePanel(
              'Awaiting Response',
              'Your complaint is waiting for an action plan from ${data['sendTo'] ?? 'the admin'}.',
              Colors.orange,
            ),
          if (status == 'In Progress') ...[
            _messagePanel(
              'Admin Message',
              adminMessage.isEmpty
                  ? 'The hostel team is working on your complaint.'
                  : adminMessage,
              Colors.teal,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isResolving ? null : () => _resolveComplaint(complaintId),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: isResolving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Upload Clean Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
          if (status == 'Resolved') ...[
            _messagePanel(
              'Resolved',
              adminMessage.isEmpty
                  ? 'The hostel team completed this complaint.'
                  : adminMessage,
              Colors.green,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _photoPanel('Before', issuePhotoBase64, 145),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _photoPanel('After', resolutionPhotoBase64, 145),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _messagePanel(String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _photoPanel(String label, String base64String, double height) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (base64String.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      base64Image: base64String,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Container(
                  width: double.infinity,
                  height: height,
                  color: Colors.grey[200],
                  child: Image.memory(
                    base64Decode(base64String),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
