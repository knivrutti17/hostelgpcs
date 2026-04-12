import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaintId,
    required this.data,
    required this.statusColor,
    required this.urgencyColor,
    required this.onMarkInProgress,
    required this.messageController,
    required this.isSaving,
  });

  final String complaintId;
  final Map<String, dynamic> data;
  final Color Function(String status) statusColor;
  final Color Function(String urgency) urgencyColor;
  final Future<void> Function(
      String complaintId, TextEditingController controller) onMarkInProgress;
  final TextEditingController messageController;
  final bool isSaving;

  String get _status => (data['status'] ?? 'Pending').toString();
  String get _issuePhotoBase64 =>
      (data['issuePhotoBase64'] ?? data['imageString'] ?? '').toString();
  String get _resolutionPhotoBase64 =>
      (data['resolutionPhotoBase64'] ?? '').toString();
  String get _wardenMessage =>
      (data['adminMessage'] ?? data['resolutionText'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp = data['timestamp'] is Timestamp
        ? DateFormat('dd MMM, hh:mm a')
            .format((data['timestamp'] as Timestamp).toDate())
        : 'Recent';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Roll No: ${data['rollNo'] ?? '--'} | Room No: ${data['roomNo'] ?? '--'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Branch: ${data['branch'] ?? 'Not available'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  text: _status,
                  color: statusColor(_status),
                  backgroundOpacity: 0.12,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  text: (data['category'] ?? 'General').toString(),
                  color: const Color(0xFF1A237E),
                  backgroundOpacity: 0.08,
                ),
                _InfoChip(
                  text: (data['urgency'] ?? 'Low').toString(),
                  color: urgencyColor((data['urgency'] ?? 'Low').toString()),
                  backgroundOpacity: 0.1,
                ),
                _InfoChip(
                  text: formattedTimestamp,
                  color: Colors.blueGrey,
                  backgroundOpacity: 0.08,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (data['description'] ?? '').toString(),
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ImagePreviewTile(
                    label: 'View Before Image',
                    base64Image: _issuePhotoBase64,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ImagePreviewTile(
                    label: 'View After Image',
                    base64Image: _resolutionPhotoBase64,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_status == 'Pending') ...[
              TextField(
                controller: messageController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Warden message / ETA',
                  hintText: 'Example: Electrician scheduled by 5 PM today.',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () => onMarkInProgress(complaintId, messageController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Send Warden Message',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ] else
              _MessagePanel(message: _wardenMessage),
          ],
        ),
      ),
    );
  }
}

class ImagePreviewTile extends StatelessWidget {
  const ImagePreviewTile({
    super.key,
    required this.label,
    required this.base64Image,
  });

  final String label;
  final String base64Image;

  Uint8List? _decodeBytes() {
    if (base64Image.isEmpty) return null;
    try {
      return base64Decode(base64Image);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBytes();
    final hasImage = bytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasImage
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      base64Image: base64Image,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade200,
                  child: bytes == null
                      ? Icon(
                          base64Image.isEmpty
                              ? Icons.image_outlined
                              : Icons.broken_image_outlined,
                          size: 20,
                          color: Colors.grey.shade500,
                        )
                      : Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasImage
                        ? const Color(0xFF1A237E)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: hasImage ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.text,
    required this.color,
    this.backgroundOpacity = 0.1,
  });

  final String text;
  final Color color;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9DEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warden Message',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.isEmpty
                ? 'No message was recorded for this complaint.'
                : message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class WardenComplaintView extends StatefulWidget {
  const WardenComplaintView({super.key});

  @override
  State<WardenComplaintView> createState() => _WardenComplaintViewState();
}

class _WardenComplaintViewState extends State<WardenComplaintView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _messageControllers = {};
  final Set<String> _savingIds = {};
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Warden Maintenance Desk',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Complaints assigned to the Warden with evidence-first closure.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by student, room, roll no, or issue...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1A237E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .where('sendTo', isEqualTo: 'Warden')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = (snapshot.data?.docs ?? []).toList()
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
                        'No complaints assigned to the Warden right now.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
    final adminMessage = _adminMessage(data);
    final controller = _controllerFor(complaintId, adminMessage);
    final isSaving = _savingIds.contains(complaintId);

    return ComplaintCard(
      complaintId: complaintId,
      data: data,
      statusColor: _statusColor,
      urgencyColor: _urgencyColor,
      onMarkInProgress: _markInProgress,
      messageController: controller,
      isSaving: isSaving,
    );
  }
}
