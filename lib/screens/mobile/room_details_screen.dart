import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({super.key});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  String? _myRoomNo;
  String? _myRollNo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRoomData();
  }

  // 1. Fetch current student's room assignment directly from Firestore
  Future<void> _initRoomData() async {
    final prefs = await SharedPreferences.getInstance();
    String? roll = prefs.getString('user_roll');
    String? room;

    if (roll != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(roll).get();
        if (userDoc.exists) {
          room = userDoc.data()?['roomNo']?.toString();
        }
      } catch (e) {
        debugPrint("Error fetching room details: $e");
      }
    }

    setState(() {
      _myRollNo = roll;
      _myRoomNo = room;
      _isLoading = false;
    });
  }

  // 2. Dial logic: Uses the tel: scheme to open the mobile dialer
  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == "None") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student contact number not available"))
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not open dialer';
      }
    } catch (e) {
      debugPrint("Call failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Room Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_myRoomNo == null ? "Room Not Assigned" : "Partners in Room $_myRoomNo",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_myRoomNo != null)
              StreamBuilder<QuerySnapshot>(
                // Filter users to only show those in the same room
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('roomNo', isEqualTo: _myRoomNo)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text("Error loading roommates");
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // Filter out the logged-in student (Viraj) from the partner list
                  final partners = snapshot.data!.docs
                      .where((doc) => doc.id != _myRollNo)
                      .toList();

                  if (partners.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No room partners found.",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: partners.length,
                    itemBuilder: (context, index) {
                      var data = partners[index].data() as Map<String, dynamic>;
                      return _buildPartnerCard(
                        data['name'] ?? "Unknown",
                        data['rollNo'] ?? "---",
                        // FIXED: Using parentMobile field which stores the mobile number
                        data['contact']?.toString() ?? "None",
                      );
                    },
                  );
                },
              )
            else
              const Center(child: Text("Contact warden for room assignment.")),

            const SizedBox(height: 24),
            const Text("Room Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRoomGallery(),
            const SizedBox(height: 24),
            const Text("Facilities Included", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildFacilitiesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(String name, String enroll, String mobileNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: AppStyle.cardDecoration,
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              radius: 25,
              child: Icon(Icons.person, color: AppStyle.primaryTeal)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Enroll No: $enroll", style: const TextStyle(fontSize: 11, color: AppStyle.textGrey)),
                ]
            ),
          ),
          // CALL BUTTON: Uses student's mobile number
          ElevatedButton.icon(
            onPressed: (mobileNumber != "None" && mobileNumber.isNotEmpty) ? () => _makeCall(mobileNumber) : null,
            icon: const Icon(Icons.call, size: 14, color: Colors.brown),
            label: const Text("Call", style: TextStyle(color: Colors.brown, fontSize: 11)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBE9D0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGallery() {
    return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[200],
            image: const DecorationImage(
                image: NetworkImage('https://i.pinimg.com/originals/c9/48/e5/c948e51a317b5a8887854d31ed649ead.jpg'),
                fit: BoxFit.cover
            )
        )
    );
  }

  Widget _buildFacilitiesGrid() {
    final facilities = [
      {"icon": Icons.bed, "label": "Two Beds"},
      {"icon": Icons.table_restaurant, "label": "Study Table & Chair"},
      {"icon": Icons.bathtub, "label": "Attached Bathroom"},
      {"icon": Icons.inventory_2, "label": "Wardrobe"},
      {"icon": Icons.ac_unit, "label": "Air Conditioner (A/C)"},
      {"icon": Icons.wifi, "label": "Wi-Fi"},
    ];
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2
        ),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyle.accentTeal.withOpacity(0.2))
              ),
              child: Row(
                  children: [
                    Icon(facilities[index]['icon'] as IconData, size: 16, color: AppStyle.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(child: Text(facilities[index]['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    const Icon(Icons.check_circle, size: 14, color: Colors.green)
                  ]
              )
          );
        }
    );
  }
}