import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/screens/mobile/style/style.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Room Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppStyle.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ROOM PARTNERS SECTION
            const Text("Your Room Partners", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPartnerCard("Suraj Patil", "3567", "+91 9876532100", "suraj_patil@gmail.com"),
            const SizedBox(height: 10),
            _buildPartnerCard("Rohit Kakde", "3434", "+91 9876543210", "rohit_kakde@gmail.com"),

            const SizedBox(height: 24),

            // 2. ROOM IMAGE GALLERY
            const Text("Room Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1555854817-40e098ee7f57?q=80&w=1000'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. FACILITIES INCLUDED
            const Text("Facilities Included", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.5,
              children: [
                _facilityItem(Icons.bed, "Two Beds"),
                _facilityItem(Icons.table_restaurant, "Study Table & Chair"),
                _facilityItem(Icons.bathtub, "Attached Bathroom"),
                _facilityItem(Icons.inventory_2, "Wardrobe"),
                _facilityItem(Icons.ac_unit, "Air Conditioner (A/C)"),
                _facilityItem(Icons.wifi, "Wi-Fi"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(String name, String enroll, String phone, String email) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppStyle.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppStyle.accentTeal, radius: 25, child: const Icon(Icons.person, color: AppStyle.primaryTeal)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Enroll No: $enroll", style: const TextStyle(fontSize: 11, color: AppStyle.textGrey)),
                Text(phone, style: const TextStyle(fontSize: 11, color: AppStyle.textGrey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBE9D0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text("Contact", style: TextStyle(color: Colors.brown, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _facilityItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.accentTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppStyle.primaryTeal),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
        ],
      ),
    );
  }
}