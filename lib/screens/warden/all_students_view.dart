import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Required for base64 decoding
import 'dart:typed_data'; // Required for Uint8List

class AllStudentsView extends StatefulWidget {
  const AllStudentsView({super.key});

  @override
  State<AllStudentsView> createState() => _AllStudentsViewState();
}

class _AllStudentsViewState extends State<AllStudentsView> {
  String _searchQuery = "";
  String _selectedYear = "All Years";
  String _selectedHostel = "All Hostels";

  Map<String, dynamic>? _selectedStudent;

  final List<String> _years = ["All Years", "1st year", "2nd year", "3rd year"];
  final List<String> _hostels = ["All Hostels", "Shivneri", "Devgiri"];

  static const Color portalBlue = Color(0xFF0077C2);
  static const Color portalAccent = Color(0xFF005A9E);
  static const Color portalBg = Color(0xFFF3F6FF);

  // --- NEW: Helper to handle both Network and Base64 Images ---
  ImageProvider? _getStudentImage(String? photoData) {
    if (photoData == null || photoData.isEmpty) return null;

    // Check if it's a URL
    if (photoData.startsWith('http')) {
      return NetworkImage(photoData);
    }

    // Check if it's Base64 data (matches your Firebase screenshot)
    try {
      // Sometimes Base64 strings have prefixes like 'data:image/jpeg;base64,'
      String base64String = photoData.contains(',')
          ? photoData.split(',').last
          : photoData;

      Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("Error decoding base64 image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildThemeFilterHeader(),
              Expanded(child: _buildStudentList()),
            ],
          ),
        ),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _selectedStudent == null ? 0 : 380,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                  color: portalBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 0)
              )
            ],
          ),
          child: _selectedStudent == null
              ? const SizedBox.shrink()
              : _buildStudentSideProfile(),
        ),
      ],
    );
  }

  Widget _buildThemeFilterHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: portalBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search name or roll number...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildThemeDropdown(_selectedHostel, _hostels, (v) => setState(() => _selectedHostel = v ?? "All Hostels"))),
              const SizedBox(width: 12),
              Expanded(child: _buildThemeDropdown(_selectedYear, _years, (v) => setState(() => _selectedYear = v ?? "All Years"))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildThemeDropdown(String val, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          dropdownColor: portalAccent,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: portalBlue));

        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String roll = (data['rollNo'] ?? "").toString().toLowerCase();
          String year = (data['year'] ?? "").toString();
          String hostel = (data['hostel'] ?? "Shivneri").toString();

          bool matchesSearch = name.contains(_searchQuery) || roll.contains(_searchQuery);
          bool matchesYear = _selectedYear == "All Years" || year == _selectedYear;
          bool matchesHostel = _selectedHostel == "All Hostels" || hostel == _selectedHostel;

          return matchesSearch && matchesYear && matchesHostel;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool isSelected = _selectedStudent != null && _selectedStudent!['uid'] == data['uid'];

            ImageProvider? studentImg = _getStudentImage(data['photoUrl']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? portalBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? portalBlue : Colors.transparent, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                onTap: () => setState(() => _selectedStudent = data),
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: portalBg,
                      backgroundImage: studentImg,
                      child: studentImg == null ? const Icon(Icons.person, color: portalBlue) : null,
                    ),
                    Container(
                      height: 12, width: 12,
                      decoration: BoxDecoration(
                        color: data['status'] == 'Active' ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    )
                  ],
                ),
                title: Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                subtitle: Text("Roll: ${data['rollNo'] ?? '--'} • Room ${data['roomNo'] ?? '--'}", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                trailing: Icon(Icons.chevron_right, color: isSelected ? portalBlue : Colors.grey.shade400),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentSideProfile() {
    ImageProvider? profileImg = _getStudentImage(_selectedStudent!['photoUrl']);

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.black54), onPressed: () => setState(() => _selectedStudent = null)),
          title: const Text("Student Details", style: TextStyle(color: portalBlue, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: portalBlue,
                  backgroundImage: profileImg,
                  child: profileImg == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
                const SizedBox(height: 16),
                Text(_selectedStudent!['name'] ?? "Unknown", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text("Roll No: ${_selectedStudent!['rollNo'] ?? '--'}", style: const TextStyle(color: portalBlue, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 20),
                _infoTile(Icons.door_sliding_outlined, "Room", "Room ${_selectedStudent!['roomNo'] ?? '--'}"),
                _infoTile(Icons.location_city_outlined, "Hostel", _selectedStudent!['hostel'] ?? "Shivneri"),
                _infoTile(Icons.calendar_today_outlined, "Academic Year", _selectedStudent!['year'] ?? "3rd year"),
                _infoTile(Icons.phone_android_outlined, "Parent Mobile", _selectedStudent!['parentMobile'] ?? "--"),
                _infoTile(Icons.check_circle_outline, "Account Status", _selectedStudent!['status'] ?? "Active", isStatus: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: portalBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: portalBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isStatus ? (value == "Active" ? Colors.green : Colors.red) : Colors.black87
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}