import 'dart:io';
import 'dart:convert'; // Required for Base64 encoding/decoding
import 'package:flutter/foundation.dart' show kIsWeb; // Required for Web check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/models/message_model.dart';
import 'package:gpcs_hostel_portal/services/chat_service.dart';
import 'package:gpcs_hostel_portal/services/chat_control_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gpcs_hostel_portal/screens/mobile/chat/image_preview_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId, chatName, userRollNo, userName, userRole;
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.userRollNo,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ChatControlService _controlService = ChatControlService();

  void _send({String type = 'text', String? imageUrl, String? text}) {
    String messageContent = text ?? _msgController.text.trim();
    if (messageContent.isEmpty && imageUrl == null) return;

    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.userRollNo,
      senderName: widget.userName,
      senderRole: widget.userRole,
      text: messageContent,
      type: type,
      imageUrl: imageUrl,
    );
    _msgController.clear();
  }

  void _showOptions(MessageModel msg, bool isStaff) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? myRoom = prefs.getString('user_room');
    String roomChatId = "room_$myRoom";
    String targetChatId = (widget.chatId == 'hostel_public') ? roomChatId : 'hostel_public';
    String targetLabel = (widget.chatId == 'hostel_public') ? "Room Chat" : "Public Chat";

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          if (!msg.isDeleted)
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF438A7F)),
              title: Text("Forward to $targetLabel"),
              onTap: () {
                _chatService.shareMessage(
                  toChatId: targetChatId,
                  originalMsg: msg,
                  senderId: widget.userRollNo,
                  senderName: widget.userName,
                );
                Navigator.pop(context);
              },
            ),
          if (isStaff && !msg.isDeleted)
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.orange),
              title: const Text("Pin Message at Top"),
              onTap: () {
                _controlService.pinMessage(widget.chatId, msg.id, msg.messageText);
                Navigator.pop(context);
              },
            ),
          // --- RESTORED: Admin/Warden Delete ---
          if (isStaff && !msg.isDeleted)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Admin Delete", style: TextStyle(color: Colors.red)),
              onTap: () {
                _controlService.adminDeleteMessage(widget.chatId, msg.id);
                Navigator.pop(context);
              },
            ),
          // --- RESTORED: Student Delete Own Message ---
          if (!isStaff && msg.senderId == widget.userRollNo && !msg.isDeleted)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete for Everyone"),
              onTap: () {
                _chatService.deleteMessage(widget.chatId, msg.id, widget.userName);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isStaff = widget.userRole == 'Admin' || widget.userRole == 'Warden';
    bool isNoticeBoard = widget.chatId == 'notice_channel';

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF438A7F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text(isStaff ? "Moderator View" : "Online", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (isStaff)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, snap) {
                bool locked = snap.data?['isLocked'] ?? false;
                return IconButton(
                  icon: Icon(locked ? Icons.lock : Icons.lock_open, color: Colors.white),
                  onPressed: () => _controlService.toggleChatLock(widget.chatId, !locked),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
        builder: (context, chatSnap) {
          var chatData = chatSnap.data?.data() as Map<String, dynamic>? ?? {};
          bool isLocked = chatData['isLocked'] ?? false;
          String? pinnedText = chatData['pinnedText'];

          return Column(
            children: [
              if (pinnedText != null)
                Container(
                  width: double.infinity,
                  color: Colors.teal.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin, size: 18, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(child: Text(pinnedText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      if (isStaff)
                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _controlService.unpinMessage(widget.chatId))
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      key: const PageStorageKey('chat_list_key'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var msg = MessageModel.fromDoc(docs[index]);
                        bool isMe = msg.senderId == widget.userRollNo;
                        return _buildBubble(msg, isMe, isStaff);
                      },
                    );
                  },
                ),
              ),
              if (isNoticeBoard && !isStaff)
                _buildReadOnlyStrip("This is an Official Notice Board.")
              else if (isLocked && !isStaff)
                _buildReadOnlyStrip("🔒 Chat is disabled by Admin.")
              else
                _buildInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyStrip(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBubble(MessageModel msg, bool isMe, bool isStaff) {
    String formattedTime = "---";
    try {
      formattedTime = DateFormat('hh:mm a').format(msg.timestamp.toDate());
    } catch (e) {
      formattedTime = "Just now";
    }

    bool isWardenMsg = msg.senderRole.toLowerCase() == 'warden' ||
        msg.senderRole.toLowerCase() == 'admin' ||
        msg.senderName.toLowerCase().contains('warden') ||
        msg.senderId == 'STAFF';

    return GestureDetector(
      onLongPress: () => _showOptions(msg, isStaff),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isWardenMsg ? "WARDEN" : (msg.senderName == "User" || msg.senderName.isEmpty ? "Student" : msg.senderName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isWardenMsg ? const Color(0xFF1A237E) : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: kIsWeb ? 400 : MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isDeleted ? Colors.grey[200] : (isMe ? const Color(0xFFDCF8C6) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty && !msg.isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(msg.imageUrl!),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                  Text(
                    msg.messageText,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                      color: msg.isDeleted ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isPinned) const Icon(Icons.push_pin, size: 10, color: Colors.grey),
                      const Spacer(),
                      Text(formattedTime, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, -1))]
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF438A7F)),
              onPressed: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (img != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImagePreviewScreen(imageFile: File(img.path)),
                    ),
                  );

                  if (result != null && result['file'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sending..."), duration: Duration(milliseconds: 800))
                    );

                    String? base64String;

                    try {
                      if (kIsWeb) {
                        final bytes = await img.readAsBytes();
                        base64String = base64Encode(bytes);
                      } else {
                        base64String = await _chatService.uploadChatImage(result['file']);
                      }

                      if (base64String != null) {
                        _send(
                          type: 'image',
                          imageUrl: base64String,
                          text: result['caption'].isEmpty ? "Sent a photo" : result['caption'],
                        );
                      }
                    } catch (e) {
                      debugPrint("Error in sending flow: $e");
                    }
                  }
                }
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF438A7F),
              child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _send()
              ),
            ),
          ],
        ),
      ),
    );
  }
}