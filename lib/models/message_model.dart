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
  // NEW FIELD: Tracks if the message was deleted
  final bool isDeleted;

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
    this.isDeleted = false, // Default to false
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'Student',
      messageText: data['messageText'] ?? '',
      messageType: data['messageType'] ?? 'text',
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      pollData: data['pollData'],
      // SAFE CHECK: Check if the field exists in Firestore, otherwise default to false
      isDeleted: data.containsKey('isDeleted') ? data['isDeleted'] : false,
    );
  }

  // Helpful method to convert the model back to a Map if needed for forwarding
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
    };
  }
}