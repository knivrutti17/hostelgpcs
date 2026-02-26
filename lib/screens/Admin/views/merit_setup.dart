import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../styles.dart';

class MeritSetupForm extends StatefulWidget {
  const MeritSetupForm({super.key});

  @override
  State<MeritSetupForm> createState() => _MeritSetupFormState();
}

class _MeritSetupFormState extends State<MeritSetupForm> {
  bool _isSaving = false;
  String _selectedHostel = 'Devgiri_boy';

  // FIXED: Direct initialization instead of 'late' to prevent LateInitializationError
  final TextEditingController _totalSeats = TextEditingController(text: "90");
  final TextEditingController _itSeats = TextEditingController(text: "30");
  final TextEditingController _civilSeats = TextEditingController(text: "30");
  final TextEditingController _mechSeats = TextEditingController(text: "30");
  final TextEditingController _openSeats = TextEditingController(text: "10");
  final TextEditingController _scSeats = TextEditingController(text: "10");
  final TextEditingController _stSeats = TextEditingController(text: "5");
  final TextEditingController _obcSeats = TextEditingController(text: "5");

  @override
  void dispose() {
    _totalSeats.dispose();
    _itSeats.dispose();
    _civilSeats.dispose();
    _mechSeats.dispose();
    _openSeats.dispose();
    _scSeats.dispose();
    _stSeats.dispose();
    _obcSeats.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;

      // Helper for branch data structure
      Map<String, dynamic> branchData(String seats) {
        return {
          'total_seats': int.tryParse(seats) ?? 0,
          'quota': {
            'open': int.tryParse(_openSeats.text) ?? 0,
            'sc': int.tryParse(_scSeats.text) ?? 0,
            'st': int.tryParse(_stSeats.text) ?? 0,
            'obc': int.tryParse(_obcSeats.text) ?? 0,
          }
        };
      }

      // Final year-wise structure
      Map<String, dynamic> yearStructure() {
        return {
          'capacity': int.tryParse(_totalSeats.text) ?? 0,
          'branches': {
            'IT': branchData(_itSeats.text),
            'Mechanical': branchData(_mechSeats.text),
            'Civil': branchData(_civilSeats.text),
          }
        };
      }

      // Sync to Firestore 'hostels' collection
      await firestore.collection('hostels').doc(_selectedHostel).set({
        '1st_year': yearStructure(),
        '2nd_year': yearStructure(),
        '3rd_year': yearStructure(),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success: $_selectedHostel Updated"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Failed: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hostel Merit & Seat Matrix Setup", style: AppStyles.headerText),
          const SizedBox(height: 20),

          // HOSTEL SELECTOR
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Text("Select Hostel to Configure: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: _selectedHostel,
                  items: const [
                    DropdownMenuItem(value: 'Devgiri_boy', child: Text("Devgiri Boy Hostel")),
                    DropdownMenuItem(value: 'Shivneri', child: Text("Shivneri Hostel")),
                  ],
                  onChanged: (val) => setState(() => _selectedHostel = val!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          _inputGroup("1. Annual Year Capacity", [_field("Total Capacity", _totalSeats)]),
          const SizedBox(height: 20),
          _inputGroup("2. Branch Quota (Per Year)", [
            _field("IT Dept", _itSeats),
            _field("Civil Dept", _civilSeats),
            _field("Mechanical", _mechSeats),
          ]),
          const SizedBox(height: 20),
          _inputGroup("3. Category Quota (Per Branch)", [
            _field("Open Seats", _openSeats),
            _field("SC Seats", _scSeats),
            _field("ST Seats", _stSeats),
            _field("OBC Seats", _obcSeats),
          ]),
          const SizedBox(height: 40),

          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
            icon: const Icon(Icons.sync, color: Colors.white),
            label: const Text("Save & Sync Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: _saveConfig,
          ),
        ],
      ),
    );
  }

  Widget _inputGroup(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const Divider(),
        Wrap(children: fields),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller, // Ensuring controller is pre-initialized
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}