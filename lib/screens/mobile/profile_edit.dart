import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEdit extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const ProfileEdit({super.key, required this.studentData});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _bloodGroupController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentData['name']);
    _contactController = TextEditingController(text: widget.studentData['contact']);
    _bloodGroupController = TextEditingController(text: widget.studentData['bloodGroup']);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 40);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? base64Image = widget.studentData['photoUrl'];
    String rollNo = widget.studentData['rollNo'];

    try {
      if (_imageFile != null) {
        Uint8List imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      await FirebaseFirestore.instance.collection('users').doc(rollNo).update({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'photoUrl': base64Image,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIXED SECTION: Corrected ImageProvider logic
  Widget _buildPhotoSection() {
    ImageProvider? imageProvider;

    if (_imageFile != null) {
      // User just picked a new file from camera/gallery
      imageProvider = FileImage(_imageFile!);
    } else if (widget.studentData['photoUrl'] != null && widget.studentData['photoUrl'].toString().isNotEmpty) {
      // Use existing Base64 string from Firestore
      try {
        imageProvider = MemoryImage(base64Decode(widget.studentData['photoUrl']));
      } catch (e) {
        debugPrint("Image decode error: $e");
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.blueGrey[50],
              backgroundImage: imageProvider, // Correctly typed ImageProvider?
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 80, color: Colors.blueGrey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: _showPicker,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF438A7F), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { _pickImage(ImageSource.gallery); Navigator.pop(ctx); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { _pickImage(ImageSource.camera); Navigator.pop(ctx); }),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, String value, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[100],
        ),
        enabled: enabled,
      ),
    );
  }

  Widget _buildEditableField(IconData icon, String label, TextEditingController controller, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF438A7F)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF438A7F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 30),
              _buildField(Icons.assignment_outlined, "Roll Number", widget.studentData['rollNo'], enabled: false),
              _buildField(Icons.business_center_outlined, "Branch", widget.studentData['department'] ?? 'IT', enabled: false),
              const Divider(height: 40),
              _buildEditableField(Icons.person_outline, "Full Name", _nameController),
              _buildEditableField(Icons.phone_outlined, "Contact", _contactController, isPhone: true),
              _buildEditableField(Icons.bloodtype_outlined, "Blood Group", _bloodGroupController),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}