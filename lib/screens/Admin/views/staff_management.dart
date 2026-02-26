import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../styles.dart';

class StaffManagementView extends StatefulWidget {
  const StaffManagementView({super.key});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  String _filterRole = "All";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Staff Role Management", style: AppStyles.headerText),
            ElevatedButton.icon(
              onPressed: () => _showAddStaffDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Register New Staff"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Advanced Filter Row
        Row(
          children: ["All", "WARDEN", "HOD"].map((role) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(role),
                selected: _filterRole == role,
                onSelected: (val) => setState(() => _filterRole = role),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text("Data load error");
            if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

            final staff = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final role = (data['role'] ?? "").toString().toUpperCase();
              if (role == "ADMIN") return false;
              return _filterRole == "All" || role == _filterRole;
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final data = staff[index].data() as Map<String, dynamic>;
                final bool isActive = data['status'] == 'Active'; // Suggested field

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                          child: Icon(Icons.person, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("${data['role']} | ${data['branch'] ?? 'General'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 5),
                              _statusChip(isActive),
                            ],
                          ),
                        ),
                        // Professional Action Buttons
                        Column(
                          children: [
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.email_outlined, color: Colors.blue, size: 20), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.green, size: 20), onPressed: () {}),
                                IconButton(
                                  icon: const Icon(Icons.lock_reset, color: Colors.orange, size: 20),
                                  onPressed: () => _resetPassword(data['email']),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _toggleStatus(staff[index].id, isActive),
                              child: Text(isActive ? "Deactivate" : "Activate", style: TextStyle(color: isActive ? Colors.red : Colors.green)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? "ACTIVE" : "INACTIVE",
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Support functions
  void _resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset Link Sent!")));
  }

  void _toggleStatus(String docId, bool currentStatus) {
    FirebaseFirestore.instance.collection('users').doc(docId).update({
      'status': currentStatus ? 'Inactive' : 'Active'
    });
  }

  void _showAddStaffDialog(BuildContext context) {
    // Logic to show a popup form to add email, name, and role to Firestore
  }
}