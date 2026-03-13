import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class StaffManagementView extends StatefulWidget {
  const StaffManagementView({super.key});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  String _filterRole = "All";
  String _searchQuery = "";
  Map<String, dynamic>? _selectedUser;

  // Cache to prevent image blinking during stream updates
  final Map<String, ImageProvider> _imageCache = {};

  static const Color adminBlue = Color(0xFF0077C2);
  static const Color adminBg = Color(0xFFF8FAFF);
  static const Color textPrimary = Color(0xFF1A237E);

  // Optimized Image Loader with Caching logic
  ImageProvider _getUserImage(String? uid, String? photoData) {
    if (uid != null && _imageCache.containsKey(uid)) return _imageCache[uid]!;

    ImageProvider provider;
    if (photoData == null || photoData.isEmpty) {
      provider = const AssetImage('assets/images/default_user.png');
    } else if (photoData.startsWith('http')) {
      provider = NetworkImage(photoData);
    } else {
      try {
        String base64String = photoData.contains(',') ? photoData.split(',').last : photoData;
        provider = MemoryImage(base64Decode(base64String));
      } catch (e) {
        provider = const AssetImage('assets/images/default_user.png');
      }
    }

    if (uid != null) _imageCache[uid] = provider;
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBg,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderActions(),
                  const SizedBox(height: 20),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildUserList()),
                ],
              ),
            ),
          ),
          if (_selectedUser != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(left: BorderSide(color: Color(0xFFE0E0E0))),
                boxShadow: [BoxShadow(color: adminBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(-5, 0))],
              ),
              child: _buildProfileSidePanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Identity & Access Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            Text("Manage user security and credentials", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text("REGISTER NEW STAFF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search name, roll no, or ID...",
                prefixIcon: Icon(Icons.search, color: adminBlue),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Wrap(
            spacing: 8,
            children: ["All", "warden", "student", "hod"].map((role) {
              bool isSelected = _filterRole.toLowerCase() == role.toLowerCase();
              return ChoiceChip(
                label: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : adminBlue, fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: adminBlue,
                onSelected: (val) => setState(() => _filterRole = role),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: adminBlue));

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? "").toString().toLowerCase();
          final id = (data['rollNo'] ?? data['employeeID'] ?? "").toString().toLowerCase();
          final role = (data['role'] ?? "").toString().toLowerCase();
          bool matchesRole = _filterRole == "All" || role == _filterRole.toLowerCase();
          bool matchesSearch = name.contains(_searchQuery) || id.contains(_searchQuery);
          return matchesRole && matchesSearch && role != "admin";
        }).toList();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String uid = data['uid'] ?? docs[index].id;
            final bool isSelected = _selectedUser?['uid'] == uid;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? adminBlue.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? adminBlue : Colors.grey.shade200, width: 1.2),
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedUser = {...data, 'uid': uid}),
                leading: CircleAvatar(
                  backgroundColor: adminBg,
                  backgroundImage: _getUserImage(uid, data['photoUrl']),
                ),
                title: Text(data['name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${data['role']?.toString().toUpperCase()} • ID: ${data['rollNo'] ?? data['employeeID'] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSidePanel() {
    final data = _selectedUser!;
    return Column(
      children: [
        AppBar(
          backgroundColor: adminBlue,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedUser = null)),
          title: const Text("Management Detail", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(radius: 60, backgroundImage: _getUserImage(data['uid'], data['photoUrl'])),
                const SizedBox(height: 16),
                Text(data['name'] ?? "Unknown", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                Text("Role: ${data['role']?.toString().toUpperCase()}", style: const TextStyle(color: adminBlue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                _actionButton("Update Account Password", Icons.lock_reset_rounded, Colors.orange,
                        () => _showPasswordUpdateDialog(data['uid'], data['email'])),

                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                _infoRow(Icons.email_outlined, "Official Email", data['email'] ?? "N/A"),
                _infoRow(Icons.badge_outlined, "Official ID", data['employeeID'] ?? data['rollNo'] ?? "N/A"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- PASSWORD UPDATE DIALOG (DIRECT FIRESTORE UPDATE) ---
  void _showPasswordUpdateDialog(String uid, String email) {
    final TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Admin Password Override", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Setting new permanent password for: $email", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.password_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (passController.text.isEmpty) return;
              try {
                // Permanently update student account in Firestore
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'customPassword': passController.text,
                  'passwordChanged': true,
                  'lastAdminAction': 'Password manually updated by Admin',
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Account Credentials Updated Successfully!"), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Save Permanent"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, size: 18, color: adminBlue),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }
}