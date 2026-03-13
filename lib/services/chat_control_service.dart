import 'package:cloud_firestore/cloud_firestore.dart';

class ChatControlService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CHAT MANAGEMENT (Admin/Warden only) ---

  // Toggle Chat Lock: When true, students cannot type
  Future<void> toggleChatLock(String chatId, bool lockStatus) async {
    await _db.collection('chats').doc(chatId).update({
      'isLocked': lockStatus,
    });
  }

  // Pin a Message: Makes it appear in the top header
  Future<void> pinMessage(String chatId, String messageId, String text) async {
    await _db.collection('chats').doc(chatId).update({
      'pinnedMessageId': messageId,
      'pinnedText': text,
    });
  }

  // Unpin Message: Removes the top header
  Future<void> unpinMessage(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'pinnedMessageId': null,
      'pinnedText': null,
    });
  }

  // Admin Delete: Moderator override to remove any student's message
  Future<void> adminDeleteMessage(String chatId, String messageId) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'messageText': "🚫 Message removed by Moderator",
      'isDeleted': true,
      'imageUrl': null,
    });
  }

  // --- OFFICIAL NOTICE BOARD ---

  // SEND OFFICIAL NOTICE: Staff-only channel for permanent announcements
  Future<void> sendOfficialNotice({
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    // Fixed ID for the official notice channel
    String chatId = 'notice_channel';

    // 1. Add the actual message to the sub-collection
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': 'OFFICIAL',
      'senderName': senderName,
      'senderRole': 'Staff',
      'messageText': text,
      'type': imageUrl != null ? 'image' : 'text',
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isPinned': true, // Notices are pinned to stay prominent
      'isDeleted': false,
    });

    // 2. Update the Chat List preview for the dashboard
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSender': senderName,
      'name': 'Official Notices', // Ensures the name persists
      'type': 'notice',
    }, SetOptions(merge: true));
  }
}