import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:gpcs_hostel_portal/models/message_model.dart'; //// Ensure this import matches your project structure
import 'package:flutter/foundation.dart';
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

  // Upload image to Firebase Storage and return the URL
  Future<String?> uploadChatImage(File image) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = FirebaseStorage.instance.ref().child('chat_images/$fileName');
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      UploadTask uploadTask = ref.putFile(image, metadata);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  // Send message and update the parent chat document
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? imageUrl,
  }) async {
    try {
      final WriteBatch batch = _db.batch();

      DocumentReference messageRef = _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'senderId': senderId,
        'senderName': senderName,
        'messageText': text,
        'type': type,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false, // Initialize as false
      });

      DocumentReference chatRef = _db.collection('chats').doc(chatId);

      batch.set(chatRef, {
        'lastMessage': type == 'image' ? '📷 Photo' : text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSender': senderName,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  // --- NEW: DELETE MESSAGE (WhatsApp Style) ---
  Future<void> deleteMessage(String chatId, String messageId, String studentName) async {
    try {
      await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
        'messageText': "This message was deleted",
        'isDeleted': true,
        'type': 'text', // Reset type so images are no longer rendered
        'imageUrl': null, // Remove image reference
      });

      // Optional: Update lastMessage in the list view to show deletion
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': "🚫 Message deleted",
      });
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  // --- NEW: SHARE MESSAGE (Forwarding) ---
  Future<void> shareMessage({
    required String toChatId,
    required MessageModel originalMsg,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Forwarding logic: Sends the content of the original message as a new message
      await sendMessage(
        chatId: toChatId,
        senderId: senderId,
        senderName: senderName,
        text: originalMsg.messageText,
        type: originalMsg.messageType,
        imageUrl: originalMsg.imageUrl,
      );
    } catch (e) {
      debugPrint("Error sharing message: $e");
    }
  }

  // Initialize default chat rooms for a new student
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
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error initializing chats: $e");
    }
  }
}