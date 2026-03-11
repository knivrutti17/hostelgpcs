import 'package:flutter/material.dart';
import 'package:gpcs_hostel_portal/services/download_service.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Documents")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _docTile(context, "Fee Receipt", Icons.receipt_long, Colors.green),
          _docTile(context, "Hostel ID Card", Icons.badge, Colors.blue),
          _docTile(context, "Leave Report", Icons.description, Colors.orange),
        ],
      ),
    );
  }

  Widget _docTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.download),
        onTap: () => DownloadService.handleGlobalDownload(context, title),
      ),
    );
  }
}