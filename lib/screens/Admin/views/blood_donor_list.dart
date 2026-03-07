import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodDonorList extends StatefulWidget {
  const BloodDonorList({super.key});

  @override
  State<BloodDonorList> createState() => _BloodDonorListState();
}

class _BloodDonorListState extends State<BloodDonorList> {
  // Tracking the active blood group filter
  String _selectedFilter = "ALL";

  // List of standard blood groups for the professional filter bar
  final List<String> _bloodGroups = ["ALL", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Using Media Query to prevent "Bottom Overflowed" errors
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Blood Donor Registry",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)
            ),
          ),
          const SizedBox(height: 20),

          // CREATIVE UI: Horizontal Blood Group Filter Bar
          _buildFilterBar(),

          const SizedBox(height: 25),

          // DATA TABLE SECTION
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Pulls the entire student list from the 'users' collection
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // CRITICAL SAFETY: Prevents red screen TypeError
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No student records found in database.",
                          style: TextStyle(color: Colors.grey, fontSize: 16))
                  );
                }

                // Filtering: Only shows records matching the button selected
                final donors = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bloodGroup = (data['bloodGroup'] ?? "").toString().toUpperCase();
                  return _selectedFilter == "ALL" || bloodGroup == _selectedFilter;
                }).toList();

                if (donors.isEmpty) {
                  return Center(
                      child: Text("No students found with blood group: $_selectedFilter",
                          style: const TextStyle(color: Colors.grey))
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowHeight: 64,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FD)),
                          columns: const [
                            DataColumn(label: Text("STUDENT NAME", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                            DataColumn(label: Text("GROUP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                            DataColumn(label: Text("HOSTEL/ROOM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                            DataColumn(label: Text("CONTACT NO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                          ],
                          rows: donors.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            // DATABASE FIX: Pulling phone number from 'contact' field
                            String phone = (data['contact'] ?? "N/A").toString();
                            String hostel = (data['hostel'] ?? "---").toString();
                            String room = (data['roomNo'] ?? "---").toString();

                            return DataRow(cells: [
                              DataCell(Text(data['name'] ?? "Unknown",
                                  style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(_buildBloodBadge(data['bloodGroup'] ?? "??")),
                              DataCell(Text("$hostel / $room")),
                              DataCell(Row(
                                children: [
                                  const Icon(Icons.phone_android, size: 16, color: Colors.indigo),
                                  const SizedBox(width: 8),
                                  Text(phone,
                                      style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold
                                      )
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the horizontal filter chips
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _bloodGroups.map((group) {
          bool isSelected = _selectedFilter == group;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(group),
              selected: isSelected,
              selectedColor: const Color(0xFF1A237E),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold
              ),
              onSelected: (selected) {
                setState(() => _selectedFilter = group);
              },
              backgroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper to build the red blood group badge
  Widget _buildBloodBadge(String blood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(blood,
          style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12
          )
      ),
    );
  }
}