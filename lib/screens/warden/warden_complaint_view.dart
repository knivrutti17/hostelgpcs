import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class WardenComplaintView extends StatefulWidget {
  const WardenComplaintView({super.key});

  @override
  State<WardenComplaintView> createState() => _WardenComplaintViewState();
}

class _WardenComplaintViewState extends State<WardenComplaintView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FIXED: Centered dialog for professional look
  void _viewFullImage(String base64String) {
    final String cleanString = base64String.contains(',') ? base64String.split(',')[1] : base64String;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            Flexible(child: Image.memory(base64Decode(cleanString), fit: BoxFit.contain)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('complaints').where('sendTo', isEqualTo: 'Warden').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No Pending Complaints."));

              final filtered = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['studentName'] ?? "").toString().toLowerCase();
                final room = (data['roomNo'] ?? "").toString().toLowerCase();
                return name.contains(_searchQuery) || room.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  var data = filtered[index].data() as Map<String, dynamic>;
                  String? imgStr = data['imageString'];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showStatusDialog(context, filtered[index].id, data),
                      leading: imgStr != null
                          ? GestureDetector(onTap: () => _viewFullImage(imgStr), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(imgStr.split(',')[1]), width: 50, height: 50, fit: BoxFit.cover)))
                          : const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.build, color: Colors.blue)),
                      title: Text("Room ${data['roomNo'] ?? '---'}: ${data['studentName'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['description'] ?? "No description", maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Chip(
                        label: Text(data['status'] ?? "Pending", style: const TextStyle(fontSize: 10)),
                        backgroundColor: data['status'] == 'Resolved' ? Colors.green.shade100 : Colors.orange.shade100,
                      ),
                    ),
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
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hostel Maintenance Complaints", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(hintText: "Search by Name or Room...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[50]),
          ),
        ],
      ),
    );
  }

  // FIXED: SingleChildScrollView added to prevent bottom overflow
  void _showStatusDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController reasonController = TextEditingController();
    String? imgStr = data['imageString'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complaint Action"),
        content: SingleChildScrollView( // CRITICAL FIX
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imgStr != null) ...[
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(imgStr.split(',')[1]), height: 180, fit: BoxFit.cover)),
                const SizedBox(height: 15),
              ],
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: "Resolution/Rejection Reason", border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => _updateStatus(docId, 'Rejected', reasonController.text), child: const Text("Reject", style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => _updateStatus(docId, 'Resolved', reasonController.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Resolve")),
        ],
      ),
    );
  }

  void _updateStatus(String docId, String status, String reason) {
    FirebaseFirestore.instance.collection('complaints').doc(docId).update({'status': status, 'resolutionText': reason});
    Navigator.pop(context);
  }
}