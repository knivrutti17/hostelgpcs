import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Required for web check
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  const ImagePreviewScreen({super.key, required this.imageFile});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Preview", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Image View Area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: kIsWeb
                  ? Image.network(
                widget.imageFile.path,
                fit: BoxFit.contain,
                // Error handling for web blobs
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text("Unable to preview image on Web", style: TextStyle(color: Colors.white)),
                ),
              )
                  : Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Caption Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Add a caption...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {
                        'file': widget.imageFile,
                        'caption': _captionController.text.trim(),
                      });
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF438A7F),
                      radius: 25,
                      child: Icon(Icons.send, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}