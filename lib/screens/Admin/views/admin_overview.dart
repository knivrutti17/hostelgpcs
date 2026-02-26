import 'package:flutter/material.dart';
import '../widgets/admin_stat_card.dart';
import '../../../styles.dart';

class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Administrative Overview", style: AppStyles.headerText),
        const SizedBox(height: 20),
        const Row(
          children: [
            AdminStatCard(label: "Total Seats", value: "180", color: Colors.blue),
            AdminStatCard(label: "Allocated Seats", value: "120", color: Colors.green),
            AdminStatCard(label: "Available Seats", value: "60", color: Colors.red),
            AdminStatCard(label: "Pending Apps", value: "18", color: Colors.purple),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildAllocationChart()),
            const SizedBox(width: 20),
            Expanded(flex: 1, child: _buildQuickActions()),
          ],
        ),
      ],
    );
  }

  Widget _buildAllocationChart() {
    return Card(
      elevation: 2,
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        child: const Center(child: Text("Live Visualization Chart Area")),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _actionCard("Create Merit List", Icons.list_alt, AppColors.primaryBlue),
        _actionCard("Allocate Seats", Icons.check_circle, Colors.green),
        _actionCard("Cancel Allocation", Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {},
      ),
    );
  }
}