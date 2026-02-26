import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../styles.dart';

class MeritSetupView extends StatefulWidget {
  const MeritSetupView({super.key});

  @override
  State<MeritSetupView> createState() => _MeritSetupViewState();
}

class _MeritSetupViewState extends State<MeritSetupView> {
  String _selectedHostel = 'Devgiri_boy'; // Document ID from Admin

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Hostel Merit Setup (Read-Only View)", style: AppStyles.headerText),
            DropdownButton<String>(
              value: _selectedHostel,
              items: const [
                DropdownMenuItem(value: 'Devgiri_boy', child: Text("Devgiri Boy")),
                DropdownMenuItem(value: 'Shivneri', child: Text("Shivneri")),
              ],
              onChanged: (val) => setState(() => _selectedHostel = val!),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            // Listens to 'hostels' collection as defined in Admin setup
            stream: FirebaseFirestore.instance.collection('hostels').doc(_selectedHostel).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("No configuration data found in Firebase for this hostel."));
              }

              var data = snapshot.data!.data() as Map<String, dynamic>;

              return ListView(
                children: [
                  _displayYearSection("1st Year (FY)", data['1st_year']),
                  _displayYearSection("2nd Year (SY)", data['2nd_year']),
                  _displayYearSection("3rd Year (TY)", data['3rd_year']),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _displayYearSection(String title, Map<String, dynamic>? yearData) {
    if (yearData == null) return const SizedBox();
    var branches = yearData['branches'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: branches.entries.map((e) => _branchDetail(e.key, e.value)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _branchDetail(String name, Map<String, dynamic> data) {
    var quota = data['quota'] as Map<String, dynamic>;
    return Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Total: ${data['total_seats']}", style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        Text("O: ${quota['open']} | SC: ${quota['sc']}", style: const TextStyle(fontSize: 11)),
        Text("ST: ${quota['st']} | OBC: ${quota['obc']}", style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}