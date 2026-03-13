import 'dart:io';
import 'dart:convert'; // Required for Base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:gpcs_hostel_portal/models/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // REQUIRED: Add to pubspec.yaml

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream messages for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // --- UPDATED: COMPRESS AND CONVERT TO BASE64 FOR FIRESTORE ---
  Future<String?> uploadChatImage(File image) async {
    try {
      final filePath = image.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jpg|.jpeg'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

      // 1. COMPRESS: Shrink image quality to 25% for instant Firestore upload
      var result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        outPath,
        quality: 25,
        minWidth: 600,
        minHeight: 600,
      );

      if (result == null) return null;

      // 2. CONVERT: Read bytes and convert to Base64 String
      List<int> imageBytes = await File(result.path).readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 3. CLEANUP: Remove the temporary compressed file from device storage
      try {
        final file = File(result.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint("Cleanup error: $e");
      }

      debugPrint("Image compressed and encoded to Base64 successfully");
      return base64Image;
    } catch (e) {
      debugPrint("Compression/Encoding Error: $e");
      return null;
    }
  }

  // --- UPDATED: Send message directly to Firestore ---
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    String type = 'text',
    String? imageUrl, // This now receives the Base64 String
  }) async {
    try {
      final WriteBatch batch = _db.batch();

      DocumentReference messageRef = _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      // Normalize role for UI labels
      String roleToSave = senderRole;
      if (senderId == 'STAFF' || senderName.toLowerCase().contains('warden')) {
        roleToSave = 'Warden';
      }

      batch.set(messageRef, {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': roleToSave,
        'messageText': text,
        'type': type,
        'imageUrl': imageUrl, // Saves the Base64 string in Firestore
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isPinned': false,
      });

      DocumentReference chatRef = _db.collection('chats').doc(chatId);

      String displaySender = (roleToSave == 'Warden' || roleToSave == 'Admin')
          ? "Warden"
          : senderName;

      batch.set(chatRef, {
        'lastMessage': type == 'image' ? '📷 Photo' : text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSender': displaySender,
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint("Message successfully saved in Firestore");
    } catch (e) {
      debugPrint("Firestore Send Error: $e");
    }
  }

  // --- DELETE MESSAGE ---
  Future<void> deleteMessage(String chatId, String messageId, String studentName) async {
    try {
      await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
        'messageText': "This message was deleted",
        'isDeleted': true,
        'type': 'text',
        'imageUrl': null,
      });

      await _db.collection('chats').doc(chatId).update({
        'lastMessage': "🚫 Message deleted",
      });
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  // --- SHARE MESSAGE ---
  Future<void> shareMessage({
    required String toChatId,
    required MessageModel originalMsg,
    required String senderId,
    required String senderName,
  }) async {
    try {
      await sendMessage(
        chatId: toChatId,
        senderId: senderId,
        senderName: senderName,
        senderRole: originalMsg.senderRole,
        text: originalMsg.messageText,
        type: originalMsg.messageType,
        imageUrl: originalMsg.imageUrl,
      );
    } catch (e) {
      debugPrint("Error sharing message: $e");
    }
  }

  // --- INITIALIZE CHATS ---
  Future<void> initializeHostelChats(String roomNo) async {
    try {
      List<Map<String, String>> defaultChats = [
        {'id': 'hostel_public', 'name': 'Hostel Public Chat', 'type': 'public'},
        {'id': 'notice_channel', 'name': 'Official Notices', 'type': 'notice'},
        {'id': 'room_$roomNo', 'name': 'Room $roomNo Chat', 'type': 'room'},
      ];

      for (var chat in defaultChats) {
        await _db.collection('chats').doc(chat['id']).set({
          'name': chat['name'],
          'type': chat['type'],
          'lastMessage': 'Welcome to ${chat['name']}!',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'isLocked': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error initializing chats: $e");
    }
  }
}