import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_thread.dart';
import '../services/chat_service.dart';

/// Sohbet (chat) durumunu yöneten sağlayıcı: kullanıcının konumunu paylaşır,
/// dahil olduğu sohbetleri canlı izler ve yakındaki kullanıcıları bulur.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  StreamSubscription<List<ChatThread>>? _sub;
  String? _uid;
  String _username = '';

  double? _lat;
  double? _lng;
  DateTime? _lastLocationWrite;

  List<ChatThread> _threads = const [];

  String? get uid => _uid;
  String get username => _username;

  /// Kullanıcının dahil olduğu sohbetler (en yeni mesaja göre).
  List<ChatThread> get threads => _threads;

  /// Konum bilindi mi? (yakındakiler için gerekir)
  bool get hasLocation => _lat != null && _lng != null;

  /// Oturum açan kullanıcıya bağlanır: adını yükler ve sohbet akışına abone olur.
  Future<void> bind(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    _username = await _service.usernameOf(uid);
    await _sub?.cancel();
    _sub = _service.myThreadsStream(uid).listen((list) {
      _threads = list;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Haritadan gelen konumu saklar ve (en fazla ~30 sn'de bir) sunucuya yazar.
  void updateMyLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    if (_lastLocationWrite != null &&
        now.difference(_lastLocationWrite!).inSeconds < 30) {
      return;
    }
    _lastLocationWrite = now;
    _service.updateMyLocation(uid: uid, lat: lat, lng: lng);
  }

  /// Geçerli konuma yakın (varsayılan 2 km) diğer kullanıcıları döner.
  Future<List<NearbyUser>> nearby({double? radiusM}) async {
    final uid = _uid;
    if (uid == null || _lat == null || _lng == null) return const [];
    return _service.nearbyUsers(
      myUid: uid,
      lat: _lat!,
      lng: _lng!,
      radiusM: radiusM ?? ChatService.defaultRadiusM,
    );
  }

  /// Bir kullanıcıyla 1:1 sohbeti açar/oluşturur ve kimliğini döner.
  Future<String?> openDirect(String otherUid, String otherName) async {
    final uid = _uid;
    if (uid == null) return null;
    return _service.openDirectChat(
      myUid: uid,
      myName: _username,
      otherUid: otherUid,
      otherName: otherName,
    );
  }

  ChatService get service => _service;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
