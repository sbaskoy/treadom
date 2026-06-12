import 'package:cloud_firestore/cloud_firestore.dart';

/// Bir sohbetteki tek mesaj: `chats/{chatId}/messages/{id}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
