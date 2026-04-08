import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../styles.dart';

class HODComplaintView extends StatelessWidget {
  const HODComplaintView({
    super.key,
    this.branchFilter = 'Information technology',
  });

  final String branchFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Student Complaints (IT Dept)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 10),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Stream strictly filtered for HOD role
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allowedIds = (userSnapshot.data?.docs ?? []).where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = (data['role'] ?? '').toString().toLowerCase();
                final branch =
                    (data['branch'] ?? data['brach'] ?? '').toString().trim();
                return role == 'student' && branch == branchFilter;
              }).map((doc) => doc.id).toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('complaints')
                    .where('sendTo', isEqualTo: 'HOD')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final studentId =
                        (data['studentUid'] ?? data['uid'] ?? data['rollNo'])
                            .toString();
                    return allowedIds.contains(studentId);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Pending Complaints for IT Department.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showStatusDialog(context, doc.id),
                          leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF3E5F5),
                              child: Icon(Icons.mail, color: Colors.purple)
                          ),
                          title: Text(
                              "${data['studentName'] ?? 'Unknown'} (${data['rollNo'] ?? '---'})",
                              style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text("Category: ${data['category'] ?? 'General'}\nDescription: ${data['description'] ?? ''}"),
                          trailing: _buildUrgencyBadge(data['urgency'] ?? "Low", data['status'] ?? "Pending"),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyBadge(String urgency, String status) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(urgency, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
        ),
      ],
    );
  }

  void _showStatusDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Complaint Status"),
        content: const Text("Mark this complaint as Resolved?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('complaints').doc(docId).update({'status': 'Resolved'});
              Navigator.pop(context);
            },
            child: const Text("Resolve"),
          ),
        ],
      ),
    );
  }
}
