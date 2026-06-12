import 'package:cloud_firestore/cloud_firestore.dart';

/// Bir sohbet başlığı (1:1 ya da grup): `chats/{id}`.
///
/// 1:1 sohbet bir tarafça bitirilebilir; bitince [status] `ended` olur ve
/// güvenlik kuralları yeni mesaj yazmayı engeller (karşıya bir daha yazılamaz).
class ChatThread {
  const ChatThread({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.participants,
    required this.participantNames,
    required this.createdBy,
    this.lastMessage,
    this.lastMessageAt,
    this.status = 'active',
    this.endedBy,
  });

  final String id;
  final bool isGroup;

  /// Grup adı (gruplarda). 1:1'de boş olabilir; karşı tarafın adı UI'da türetilir.
  final String name;

  /// Katılımcı kullanıcı kimlikleri.
  final List<String> participants;

  /// uid → kullanıcı adı eşlemesi (UI'da ad göstermek için).
  final Map<String, String> participantNames;

  final String createdBy;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// `active` ya da `ended`.
  final String status;
  final String? endedBy;

  bool get isEnded => status == 'ended';

  /// 1:1 sohbette karşı tarafın uid'i.
  String otherUid(String myUid) =>
      participants.firstWhere((u) => u != myUid, orElse: () => '');

  /// Sohbette gösterilecek başlık ([myUid]'e göre): grupta grup adı, 1:1'de
  /// karşı tarafın adı.
  String title(String myUid) {
    if (isGroup) return name;
    final other = otherUid(myUid);
    return participantNames[other] ?? '';
  }

  factory ChatThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return ChatThread(
      id: doc.id,
      isGroup: (data['isGroup'] as bool?) ?? false,
      name: (data['name'] as String?) ?? '',
      participants: ((data['participants'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      participantNames:
          ((data['participantNames'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      createdBy: (data['createdBy'] as String?) ?? '',
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      status: (data['status'] as String?) ?? 'active',
      endedBy: data['endedBy'] as String?,
    );
  }
}
