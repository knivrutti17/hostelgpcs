import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../styles.dart';

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
        child: InteractiveViewer(
          child: Image.memory(
            base64Decode(base64Image),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class HODComplaintView extends StatefulWidget {
  const HODComplaintView({
    super.key,
    this.branchFilter = 'Information technology',
  });

  final String branchFilter;

  @override
  State<HODComplaintView> createState() => _HODComplaintViewState();
}

class _HODComplaintViewState extends State<HODComplaintView> {
  static const String _itBranch = 'Information technology';

  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _messageControllers = {};
  final Set<String> _savingIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _messageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(
      String complaintId, String initialValue) {
    return _messageControllers.putIfAbsent(
      complaintId,
      () => TextEditingController(text: initialValue),
    );
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

  int _timestampValue(Map<String, dynamic> data) {
    final timestamp = data['timestamp'];
    return timestamp is Timestamp ? timestamp.millisecondsSinceEpoch : 0;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      default:
        return AppColors.primaryBlue;
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

  Future<void> _markInProgress(
    String complaintId,
    TextEditingController controller,
  ) async {
    final message = controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an action plan or ETA first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _savingIds.add(complaintId));
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'adminMessage': message,
        'status': 'In Progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint moved to In Progress.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(complaintId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Department Complaint Desk',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Showing HOD complaints for Information technology.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by student, room, roll no, or issue...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F6FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .where('sendTo', isEqualTo: 'HOD')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final branch = (doc.data()['branch'] ?? '').toString().trim();
                return branch == _itBranch;
              }).toList()
                ..sort((a, b) => _timestampValue(b.data()).compareTo(
                      _timestampValue(a.data()),
                    ));

              final filteredDocs = docs.where((doc) {
                final data = doc.data();
                if (_searchQuery.isEmpty) return true;
                return (data['studentName'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    (data['rollNo'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    (data['roomNo'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    (data['category'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    (data['description'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 72,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No HOD complaints found for Information technology.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) => _buildComplaintCard(
                    filteredDocs[index].id, filteredDocs[index].data()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(String complaintId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'Pending').toString();
    final issuePhotoBase64 = _issueBase64(data);
    final resolutionPhotoBase64 = _resolutionBase64(data);
    final adminMessage = _adminMessage(data);
    final controller = _controllerFor(complaintId, adminMessage);
    final isSaving = _savingIds.contains(complaintId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (data['studentName'] ?? 'Unknown Student').toString(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll: ${data['rollNo'] ?? '--'}  |  Room: ${data['roomNo'] ?? '--'}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Branch: ${data['branch'] ?? _itBranch}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _chip(status, _statusColor(status)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                (data['category'] ?? 'General').toString(),
                AppColors.primaryBlue,
              ),
              _chip(
                (data['urgency'] ?? 'Low').toString(),
                _urgencyColor((data['urgency'] ?? 'Low').toString()),
              ),
              _chip(
                data['timestamp'] is Timestamp
                    ? DateFormat('dd MMM, hh:mm a')
                        .format((data['timestamp'] as Timestamp).toDate())
                    : 'Recent',
                Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (data['description'] ?? '').toString(),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (status == 'Resolved') ...[
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
          ] else ...[
            _photoPanel('Issue Photo', issuePhotoBase64, 190),
          ],
          const SizedBox(height: 14),
          if (status == 'Pending') ...[
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Action plan / ETA',
                hintText:
                    'Example: Department inspection scheduled for tomorrow.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () => _markInProgress(complaintId, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Message & Mark In Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ] else ...[
            _messagePanel(adminMessage),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
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

  Widget _messagePanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Message',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.isEmpty
                ? 'No message was recorded for this complaint.'
                : message,
          ),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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
