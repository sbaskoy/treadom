import 'package:cloud_firestore/cloud_firestore.dart';

/// Bir sohbetteki tek mesaj: `chats/{chatId}/messages/{id}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
    this.deliveredTo = const [],
    this.readBy = const [],
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  /// Mesajın cihazına ulaştığı (akışta gördüğü) katılımcı uid'leri (gönderen
  /// hariç). "İletildi" göstergesi için.
  final List<String> deliveredTo;

  /// Mesajı sohbet ekranında gören katılımcı uid'leri (gönderen hariç).
  /// "Görüldü" göstergesi için.
  final List<String> readBy;

  /// Verilen kullanıcılar (genelde gönderen dışındaki tüm katılımcılar) için
  /// teslim/okunma durumu. Hiçbiri yoksa sadece "gönderildi".
  bool deliveredToAll(Iterable<String> others) =>
      others.isNotEmpty && others.every(deliveredTo.contains);

  bool readByAll(Iterable<String> others) =>
      others.isNotEmpty && others.every(readBy.contains);

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
      deliveredTo: ((data['deliveredTo'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      readBy:
          ((data['readBy'] as List?) ?? const []).whereType<String>().toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': <String>[],
        'readBy': <String>[],
      };
}
