import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class WardenComplaintView extends StatefulWidget {
  const WardenComplaintView({super.key});

  @override
  State<WardenComplaintView> createState() => _WardenComplaintViewState();
}

class _WardenComplaintViewState extends State<WardenComplaintView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Safe decoding logic for Firestore Base64 images
  Uint8List? _safeDecode(String? imgStr) {
    if (imgStr == null || imgStr.isEmpty) return null;
    try {
      String cleanBase64 = imgStr.contains(',') ? imgStr.split(',')[1] : imgStr;
      return base64Decode(cleanBase64.trim());
    } catch (e) {
      debugPrint("Image Decode Error: $e");
      return null;
    }
  }

  void _viewFullImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.memory(imageBytes, fit: BoxFit.contain)),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // BROAD FETCH: If the specific .where query isn't working, this ensures we see all complaints
            // and filter them based on the 'sendTo' field in memory.
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Filter for Warden specifically in memory to bypass missing index issues
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // 1. SendTo Filter (Case insensitive check)
                final sendTo = (data['sendTo'] ?? "").toString().toLowerCase();
                if (sendTo != 'warden') return false;

                // 2. Search Query Filter
                final name = (data['studentName'] ?? "").toString().toLowerCase();
                final room = (data['roomNo'] ?? "").toString().toLowerCase();
                final category = (data['category'] ?? "").toString().toLowerCase();

                return name.contains(_searchQuery) ||
                    room.contains(_searchQuery) ||
                    category.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final imageBytes = _safeDecode(data['imageString']);

                  return _buildComplaintCard(
                      doc.id,
                      data,
                      imageBytes,
                      key: ValueKey(doc.id)
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Warden Maintenance Desk", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const Text("Manage and resolve student hostel issues", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search by Student, Room, or Issue...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(String docId, Map<String, dynamic> data, Uint8List? imageBytes, {required Key key}) {
    Color urgencyColor = data['urgency'] == 'High' ? Colors.red : Colors.orange;

    return Card(
      key: key,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showActionSheet(context, docId, data, imageBytes),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: imageBytes != null ? () => _viewFullImage(imageBytes) : null,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    image: imageBytes != null ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover) : null,
                  ),
                  child: imageBytes == null ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: urgencyColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("Room ${data['roomNo'] ?? '---'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Text(data['studentName'] ?? 'Unknown Student', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text(data['category'] ?? "General Issue", style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(data['status'] ?? "Pending"),
                  const SizedBox(height: 5),
                  Text(
                    data['timestamp'] != null ? DateFormat('dd MMM').format((data['timestamp'] as Timestamp).toDate()) : "",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Resolved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _showActionSheet(BuildContext context, String docId, Map<String, dynamic> data, Uint8List? imageBytes) {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Resolve Complaint", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Student: ${data['studentName']}", style: const TextStyle(color: Colors.grey)),
              Text("Issue: ${data['description']}", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 15),
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(imageBytes, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Resolution/Feedback for Student",
                  hintText: "E.g. Plumber visited and tap replaced.",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(docId, 'Rejected', reasonController.text),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("REJECT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(docId, 'Resolved', reasonController.text),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("MARK RESOLVED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStatus(String docId, String status, String reason) {
    FirebaseFirestore.instance.collection('complaints').doc(docId).update({
      'status': status,
      'resolutionText': reason,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complaint marked as $status"), backgroundColor: status == 'Resolved' ? Colors.green : Colors.red));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("All clear! No pending complaints.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}