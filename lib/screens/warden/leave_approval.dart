import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApprovalView extends StatelessWidget {
  const LeaveApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(title: const Text("Manage Leave Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('leaves').where('status', isEqualTo: 'Pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: Text("${data['studentName']} (Room ${data['roomNo']})"),
                  subtitle: Text("Reason: ${data['reason']} | Dates: ${data['startDate']} - ${data['endDate']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(onPressed: () => _update(doc.id, 'Approved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Approve", style: TextStyle(color: Colors.white, fontSize: 10))),
                      const SizedBox(width: 5),
                      ElevatedButton(onPressed: () => _update(doc.id, 'Rejected'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Reject", style: TextStyle(color: Colors.white, fontSize: 10))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _update(String id, String status) => FirebaseFirestore.instance.collection('leaves').doc(id).update({'status': status});
}