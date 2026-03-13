import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessMenuPage extends StatelessWidget {
  const MessMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Matches Dashboard background
      appBar: AppBar(
        title: const Text("Weekly Mess Menu",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF438A7F), // Matches Dashboard Teal
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Professional Header Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF438A7F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("HOSTEL DINING", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Text(
                  "Today is $today",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('mess_menu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF438A7F)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Sorting Monday to Sunday
                final List<String> dayOrder = [
                  "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
                ];

                var docs = snapshot.data!.docs;
                docs.sort((a, b) => dayOrder.indexOf(a.id).compareTo(dayOrder.indexOf(b.id)));

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isToday = docs[index].id == today;

                    return _buildMenuCard(
                      day: docs[index].id,
                      breakfast: data['breakfast'] ?? "Not scheduled",
                      dinner: data['dinner'] ?? "Not scheduled",
                      isToday: isToday,
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

  Widget _buildMenuCard({required String day, required String breakfast, required String dinner, required bool isToday}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isToday ? Border.all(color: const Color(0xFF438A7F), width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF438A7F).withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isToday ? const Color(0xFF438A7F) : Colors.blueGrey.shade700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isToday)
                  const Badge(label: Text("TODAY"), backgroundColor: Color(0xFF438A7F), padding: EdgeInsets.symmetric(horizontal: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _mealDetail("BREAKFAST", Icons.wb_sunny_rounded, Colors.orange, breakfast)),
                Container(width: 1, height: 50, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(child: _mealDetail("DINNER", Icons.dark_mode_rounded, Colors.indigo, dinner)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealDetail(String title, IconData icon, Color color, String menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          menu,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          const Text("Menu is currently being updated", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}