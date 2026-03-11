import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/models/message_model.dart';
import 'package:gpcs_hostel_portal/services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId, chatName, userRollNo, userName;
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.userRollNo,
    required this.userName
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<String> _suggestions = ["Good Morning ☀️", "Anyone at the mess?", "Wallet found!", "Thank you!"];

  void _send({String type = 'text', String? imageUrl, String? text}) {
    String messageContent = text ?? _msgController.text.trim();
    if (messageContent.isEmpty && imageUrl == null) return;

    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.userRollNo,
      senderName: widget.userName,
      text: messageContent,
      type: type,
      imageUrl: imageUrl,
    );
    _msgController.clear();
  }

  // --- FIXED: FORWARD/DELETE MENU LOGIC ---
  void _showOptions(MessageModel msg) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? myRoom = prefs.getString('user_room');
    String roomChatId = "room_$myRoom";

    // Determine target for forwarding
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
              onTap: () { // FIXED: Changed onPressed to onTap
                _chatService.shareMessage(
                  toChatId: targetChatId,
                  originalMsg: msg,
                  senderId: widget.userRollNo,
                  senderName: widget.userName,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Forwarded to $targetLabel")),
                );
              },
            ),
          if (msg.senderId == widget.userRollNo && !msg.isDeleted)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete for Everyone", style: TextStyle(color: Colors.red)),
              onTap: () { // FIXED: Changed onPressed to onTap
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
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const Text("Online", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF438A7F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No messages yet. Say hi!"));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var msg = MessageModel.fromDoc(docs[index]);
                      bool isMe = msg.senderId == widget.userRollNo;
                      return _buildBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            _buildSuggestions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _suggestions.map((s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: const BorderSide(color: Color(0xFF438A7F)),
            label: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF438A7F))),
            onPressed: () => _send(text: s),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBubble(MessageModel msg, bool isMe) {
    String formattedTime = "---";
    try {
      formattedTime = DateFormat('hh:mm a').format(msg.timestamp.toDate());
    } catch (e) {
      formattedTime = "Just now";
    }

    return GestureDetector(
      onLongPress: () => _showOptions(msg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(msg.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                children: [
                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty && !msg.isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: msg.imageUrl!,
                          placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF438A7F)),
              onPressed: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (img != null) {
                  String? url = await _chatService.uploadChatImage(File(img.path));
                  if (url != null) _send(type: 'image', imageUrl: url, text: "Sent an image");
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
                onPressed: () => _send(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}