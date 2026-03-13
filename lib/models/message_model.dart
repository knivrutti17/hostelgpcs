import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String messageText;
  final String messageType; // 'text', 'image', 'lost', 'found', 'poll', 'emergency'
  final String? imageUrl;
  final Timestamp timestamp;
  final Map<String, dynamic>? pollData;

  // NEW FIELDS FOR ADMIN/WARDEN CONTROLS
  final bool isDeleted;
  final bool isPinned;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.messageText,
    required this.messageType,
    this.imageUrl,
    required this.timestamp,
    this.pollData,
    this.isDeleted = false,
    this.isPinned = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // --- SMART FALLBACK LOGIC ---
    String rawRole = data['senderRole'] ?? '';
    String name = data['senderName'] ?? 'User';

    // If role is empty, check if the name indicates a staff member
    if (rawRole.isEmpty) {
      if (name.toLowerCase().contains('warden')) {
        rawRole = 'Warden';
      } else if (name.toLowerCase().contains('admin')) {
        rawRole = 'Admin';
      } else {
        rawRole = 'Student'; // Default fallback
      }
    }

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: name,
      senderRole: rawRole, // Uses the smart fallback role
      messageText: data['messageText'] ?? '',

      // --- FIXED IMAGE/TYPE MAPPING ---
      // This ensures if ChatService saves as 'type', the model reads it as 'messageType'
      messageType: data['type'] ?? data['messageType'] ?? 'text',
      imageUrl: data['imageUrl'] ?? data['image_url'], // Support multiple key variants

      timestamp: data['timestamp'] ?? Timestamp.now(),
      pollData: data['pollData'],
      // SAFE CHECKS: Default to false if the fields don't exist yet
      isDeleted: data['isDeleted'] ?? false,
      isPinned: data['isPinned'] ?? false,
    );
  }

  // Method to convert the model back to a Map for forwarding/sharing
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'messageText': messageText,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'pollData': pollData,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
    };
  }
}