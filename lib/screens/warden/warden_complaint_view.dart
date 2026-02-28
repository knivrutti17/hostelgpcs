import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../styles.dart';

class WardenComplaintView extends StatelessWidget {
  const WardenComplaintView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Hostel Maintenance Complaints",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        const SizedBox(height: 10),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // FIXED: Standardized string match and removed orderBy to prevent index errors
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .where('sendTo', isEqualTo: 'Warden')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No Pending Complaints found.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => _showStatusDialog(context, doc.id),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.build, color: Colors.blue),
                      ),
                      title: Text("Room ${data['roomNo'] ?? '---'}: ${data['studentName'] ?? 'Unknown'}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['category'] ?? 'General'}: ${data['description'] ?? ''}"),
                      trailing: Chip(
                        label: Text(data['status'] ?? "Pending", style: const TextStyle(fontSize: 11)),
                        backgroundColor: (data['status'] == 'Resolved') ? Colors.green.shade100 : Colors.orange.shade100,
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

  void _showStatusDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Action Required"),
        content: const Text("Mark this complaint as Resolved?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('complaints').doc(docId).update({'status': 'Resolved'});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Resolve"),
          ),
        ],
      ),
    );
  }
}