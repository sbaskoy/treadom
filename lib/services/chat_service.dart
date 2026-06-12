import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';

/// Yakındaki bir kullanıcı (sohbet başlatmak için).
class NearbyUser {
  const NearbyUser({
    required this.uid,
    required this.username,
    required this.distanceM,
  });

  final String uid;
  final String username;
  final double distanceM;
}

/// Sohbet (chat) ile ilgili Firestore işlemleri: konum paylaşımı, yakındaki
/// kullanıcıları bulma, 1:1/grup sohbet oluşturma, mesajlaşma ve sohbeti
/// bitirme.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// "Yakın" sayılan varsayılan yarıçap (metre).
  static const double defaultRadiusM = 2000;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  // --- Konum ---

  /// Kullanıcının görünen adını döner (sohbet/mesaj imzası için).
  Future<String> usernameOf(String uid) async {
    final doc = await _users.doc(uid).get();
    return (doc.data()?['username'] as String?) ?? '';
  }

  /// Kullanıcının son konumunu user dökümanına yazar (yakındakiler için).
  Future<void> updateMyLocation({
    required String uid,
    required double lat,
    required double lng,
  }) {
    return _users.doc(uid).set({
      'lastLat': lat,
      'lastLng': lng,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Verilen konuma [radiusM] metre içindeki diğer kullanıcıları döner
  /// (kendisi hariç). Ölçek küçük olduğundan tüm kullanıcılar okunup istemcide
  /// filtrelenir; büyük ölçekte geohash sorgusuna geçilmeli.
  Future<List<NearbyUser>> nearbyUsers({
    required String myUid,
    required double lat,
    required double lng,
    double radiusM = defaultRadiusM,
  }) async {
    final me = LatLng(lat, lng);
    const distance = Distance();
    final snap = await _users.get();
    final result = <NearbyUser>[];
    for (final doc in snap.docs) {
      if (doc.id == myUid) continue;
      final data = doc.data();
      final dLat = (data['lastLat'] as num?)?.toDouble();
      final dLng = (data['lastLng'] as num?)?.toDouble();
      if (dLat == null || dLng == null) continue;
      final d = distance.as(LengthUnit.Meter, me, LatLng(dLat, dLng));
      if (d <= radiusM) {
        result.add(NearbyUser(
          uid: doc.id,
          username: (data['username'] as String?) ?? '',
          distanceM: d,
        ));
      }
    }
    result.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return result;
  }

  // --- Sohbetler ---

  /// 1:1 sohbet için iki uid'den deterministik kimlik (sıralı birleştirme).
  String directChatId(String a, String b) {
    final sorted = [a, b]..sort();
    return 'd_${sorted[0]}_${sorted[1]}';
  }

  /// İki kullanıcı arasındaki 1:1 sohbeti açar; yoksa oluşturur. Sohbet
  /// bitirilmişse bile aynı kimliği döner (UI "bitti" durumunu gösterir).
  Future<String> openDirectChat({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
  }) async {
    final id = directChatId(myUid, otherUid);
    final ref = _chats.doc(id);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'isGroup': false,
        'name': '',
        'participants': [myUid, otherUid],
        'participantNames': {myUid: myName, otherUid: otherName},
        'createdBy': myUid,
        'status': 'active',
        'endedBy': null,
        'lastMessage': null,
        'lastMessageAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  /// Bir grup sohbeti oluşturur ve kimliğini döner.
  Future<String> createGroup({
    required String myUid,
    required String name,
    required Map<String, String> members, // uid -> username (kendisi dahil)
  }) async {
    final ref = _chats.doc();
    await ref.set({
      'isGroup': true,
      'name': name,
      'participants': members.keys.toList(),
      'participantNames': members,
      'createdBy': myUid,
      'status': 'active',
      'endedBy': null,
      'lastMessage': null,
      'lastMessageAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Belirli bir sohbeti canlı yayınlar.
  Stream<ChatThread?> threadStream(String chatId) {
    return _chats.doc(chatId).snapshots().map(
          (doc) => doc.exists ? ChatThread.fromFirestore(doc) : null,
        );
  }

  /// Kullanıcının dahil olduğu tüm sohbetleri (en yeni mesaja göre) yayınlar.
  Stream<List<ChatThread>> myThreadsStream(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(ChatThread.fromFirestore).toList();
      list.sort((a, b) {
        final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  // --- Mesajlar ---

  /// Sohbetin mesajlarını (eskiden yeniye) yayınlar.
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Bir mesaj gönderir ve sohbetin son-mesaj özetini günceller. Sohbet
  /// bitirilmişse güvenlik kuralları yazmayı reddeder.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final batch = _db.batch();
    final msgRef = _chats.doc(chatId).collection('messages').doc();
    batch.set(
      msgRef,
      ChatMessage(id: '', senderId: senderId, senderName: senderName, text: trimmed)
          .toFirestore(),
    );
    batch.update(_chats.doc(chatId), {
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Sohbeti bitirir (yalnızca 1:1 için anlamlı). Bundan sonra kimse yeni mesaj
  /// yazamaz.
  Future<void> endChat({required String chatId, required String byUid}) {
    return _chats.doc(chatId).update({
      'status': 'ended',
      'endedBy': byUid,
    });
  }
}
