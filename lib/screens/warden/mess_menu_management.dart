import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class MessMenuManagement extends StatefulWidget {
  const MessMenuManagement({super.key});

  @override
  State<MessMenuManagement> createState() => _MessMenuManagementState();
}

class _MessMenuManagementState extends State<MessMenuManagement> {
  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final Map<String, TextEditingController> _breakfastControllers = {};
  final Map<String, TextEditingController> _dinnerControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var day in _days) {
      _breakfastControllers[day] = TextEditingController();
      _dinnerControllers[day] = TextEditingController();
    }
    _fetchExistingMenu();
  }

  @override
  void dispose() {
    for (var c in _breakfastControllers.values) {c.dispose();}
    for (var c in _dinnerControllers.values) {c.dispose();}
    super.dispose();
  }

  Future<void> _fetchExistingMenu() async {
    setState(() => _isLoading = true);
    var snapshot = await FirebaseFirestore.instance.collection('mess_menu').get();
    for (var doc in snapshot.docs) {
      if (_breakfastControllers.containsKey(doc.id)) {
        _breakfastControllers[doc.id]!.text = doc['breakfast'] ?? "";
        _dinnerControllers[doc.id]!.text = doc['dinner'] ?? "";
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAllMenus() async {
    setState(() => _isLoading = true);
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var day in _days) {
      DocumentReference ref = FirebaseFirestore.instance.collection('mess_menu').doc(day);
      batch.set(ref, {
        'day': day,
        'breakfast': _breakfastControllers[day]!.text.trim(),
        'dinner': _dinnerControllers[day]!.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Weekly Menu Updated Successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // PDF Generation - Official Template Logic
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/gpcslogo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) { print("Logo load failed: $e"); }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header Section Matching your UI
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logoImage != null) pw.Image(logoImage, width: 70, height: 70),
                pw.SizedBox(width: 20),
                pw.Column(
                  children: [
                    pw.Text("Government Polytechnic", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A237E))),
                    pw.Text("Chhatrapati Sambhajinagar", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A237E))),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A237E), borderRadius: pw.BorderRadius.circular(20)),
                      child: pw.Text("Hostel Portal", style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Text("WEEKLY MESS MENU", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.SizedBox(height: 5),
            pw.Text("As Prepared & Approved by the Warden", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 15),

            // Main Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(3)},
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A237E)),
                  children: ['Day', 'Breakfast Menu', 'Dinner Menu'].map((h) => pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Center(child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))))).toList(),
                ),
                ..._days.map((day) => pw.TableRow(
                  decoration: pw.BoxDecoration(color: _days.indexOf(day) % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF5F7FF)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(day, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(_breakfastControllers[day]!.text)),
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(_dinnerControllers[day]!.text)),
                  ],
                )),
              ],
            ),

            pw.Spacer(),

            // Footer Matching your UI
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Notes Section
                pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF9E6), borderRadius: pw.BorderRadius.circular(10), border: pw.Border.all(color: PdfColors.orange100)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Note:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A237E))),
                      pw.Bullet(text: "Menu is subject to change if required.", style: const pw.TextStyle(fontSize: 8)),
                      pw.Bullet(text: "Meals are served as per hostel guidelines.", style: const pw.TextStyle(fontSize: 8)),
                      pw.Bullet(text: "Maintain cleanliness and hygiene.", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                // Signature Section
                pw.Column(
                  children: [
                    pw.SizedBox(width: 120, child: pw.Divider(thickness: 1, color: PdfColors.blue900)),
                    pw.Text("Warden Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text("Hostel Administration", style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              color: PdfColor.fromInt(0xFF1A237E),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text("Chhatrapati Sambhajinagar, Maharashtra", style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                  pw.Text("Academic Year: 2024-2025", style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                ],
              ),
            ),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManagementHeader(),
            const SizedBox(height: 25),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Advanced 3-column layout for web
                childAspectRatio: 1.4,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _days.length,
              itemBuilder: (context, index) => _buildProfessionalDayCard(_days[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mess Menu Management", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            Text("Update weekly schedule for Academic Year ${DateTime.now().year}-${DateTime.now().year + 1}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _generatePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Export Official PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
            ),
            const SizedBox(width: 15),
            ElevatedButton.icon(
              onPressed: _saveAllMenus,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Save & Publish Week"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalDayCard(String day) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade50), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 16)),
              Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade200),
            ],
          ),
          const Divider(height: 20),
          _inputLabel("BREAKFAST MENU"),
          _buildTextField(_breakfastControllers[day]!, Icons.restaurant, Colors.orange),
          const SizedBox(height: 12),
          _inputLabel("DINNER MENU"),
          _buildTextField(_dinnerControllers[day]!, Icons.set_meal, Colors.indigo),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));

  Widget _buildTextField(TextEditingController controller, IconData icon, Color color) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 16, color: color),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}