import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../styles.dart';

class UserLogsView extends StatefulWidget {
  const UserLogsView({super.key});

  @override
  State<UserLogsView> createState() => _UserLogsViewState();
}

class _UserLogsViewState extends State<UserLogsView> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight - 200,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROFESSIONAL HEADER WITH TOGGLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("User Activity Reports", style: AppStyles.headerText),
              _buildLoggingSwitch(),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('activity_logs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No activity entries found."));
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (t1 == null || t2 == null) return 0;
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    DateTime logDate = DateTime.now();
                    if (data['timestamp'] != null) {
                      logDate = (data['timestamp'] as Timestamp).toDate();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                          child: const Icon(Icons.history, color: AppColors.primaryBlue, size: 20),
                        ),
                        title: Text(data['event']?.toString() ?? "User Login",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text("${data['email'] ?? 'Unknown'} | ${data['role']?.toString().toUpperCase() ?? ''}",
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          DateFormat('MMM dd, hh:mm a').format(logDate),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // BUILDER FOR THE ON/OFF SWITCH
  Widget _buildLoggingSwitch() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system_settings').doc('logging_config').snapshots(),
      builder: (context, snapshot) {
        bool isLogging = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          isLogging = snapshot.data!.get('isLoggingEnabled') ?? false;
        }

        return Row(
          children: [
            Text(
              isLogging ? "Logging: ON" : "Logging: OFF",
              style: TextStyle(
                color: isLogging ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isLogging,
              activeColor: Colors.green,
              onChanged: (val) async {
                await FirebaseFirestore.instance
                    .collection('system_settings')
                    .doc('logging_config')
                    .set({'isLoggingEnabled': val}, SetOptions(merge: true));
              },
            ),
          ],
        );
      },
    );
  }
}