import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/run_record.dart';
import '../models/territory.dart';
import '../services/firestore_service.dart';
import '../services/geo.dart';
import '../services/run_math.dart' show planarAreaM2;

/// Sıralama (leaderboard) tablosundaki tek bir kullanıcı satırı.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.areaM2,
    required this.territoryCount,
  });

  final String uid;
  final String username;

  /// Kullanıcının elindeki tüm alanların toplamı (metrekare).
  final double areaM2;

  /// Kullanıcının elindeki alan sayısı.
  final int territoryCount;
}

/// Harita üzerindeki alanları (kendi + rakip) ve fethetme işlemini yöneten
/// sağlayıcı.
///
/// Oturum açan kullanıcıya [bind] ile bağlanır; o kullanıcının görünen adını
/// yükler ve tüm alanların canlı akışına abone olur. Tur bitince [claim] ile
/// yeni alan oluşturulur ve çakışan rakip alanlar fethedilir.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider({FirestoreService? firestore})
      : _fs = firestore ?? FirestoreService();

  final FirestoreService _fs;

  StreamSubscription<List<Territory>>? _sub;

  String? _uid;
  String _username = '';
  String _landName = '';

  /// Şu an bağlı kullanıcının görünen adı (alan adı boş bırakılınca kullanılır).
  String get username => _username;

  /// Kullanıcının tek alan adı (boşsa kullanıcı adına düşer). Tüm alanlarında
  /// bu görünür; Ayarlar'dan değiştirilir.
  String get landName =>
      _landName.trim().isEmpty ? _username : _landName.trim();

  /// Bağlı kullanıcının kimliği.
  String? get uid => _uid;

  List<Territory> _territories = const [];

  /// Haritada çizilecek tüm alanlar (kendi + rakip).
  List<Territory> get territories => _territories;

  /// Sağlayıcıyı oturum açan kullanıcıya bağlar. Kullanıcı değişmediyse
  /// (aynı uid) tekrar abone olmaz.
  Future<void> bind(String uid) async {
    if (_uid == uid) return;
    _uid = uid;

    final user = await _fs.getUser(uid);
    _username = user?.username ?? '';
    _landName = user?.landName ?? '';

    await _sub?.cancel();
    _sub = _fs.territoriesStream().listen((list) {
      _territories = list;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Kullanıcının tek alan adını değiştirir (Ayarlar'dan). Mevcut tüm alanlarının
  /// etiketi de güncellenir.
  Future<void> setLandName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await _fs.updateLandName(uid: uid, landName: name);
    _landName = name.trim();
    notifyListeners();
  }

  /// Bir alanın bağlı kullanıcıya ait olup olmadığını döner.
  bool isMine(Territory t) => t.ownerUid == _uid;

  /// Tüm kullanıcıların toplam alanına göre azalan sıralaması.
  ///
  /// Denormalize bir toplam tutmak yerine her seferinde alan akışından
  /// hesaplanır; böylece fetihle sahiplik değişince sıralama her zaman
  /// tutarlıdır.
  List<LeaderboardEntry> get leaderboard {
    final areaByUid = <String, double>{};
    final countByUid = <String, int>{};
    final nameByUid = <String, String>{};
    for (final t in _territories) {
      areaByUid[t.ownerUid] = (areaByUid[t.ownerUid] ?? 0) + t.areaM2;
      countByUid[t.ownerUid] = (countByUid[t.ownerUid] ?? 0) + 1;
      nameByUid[t.ownerUid] = t.ownerUsername;
    }
    final entries = areaByUid.keys
        .map((uid) => LeaderboardEntry(
              uid: uid,
              username: nameByUid[uid] ?? '',
              areaM2: areaByUid[uid] ?? 0,
              territoryCount: countByUid[uid] ?? 0,
            ))
        .toList();
    entries.sort((a, b) => b.areaM2.compareTo(a.areaM2));
    return entries;
  }

  /// Bağlı kullanıcının sıralamadaki yeri (1 tabanlı); hiç alanı yoksa null.
  int? get myRank {
    final lb = leaderboard;
    for (var i = 0; i < lb.length; i++) {
      if (lb[i].uid == _uid) return i + 1;
    }
    return null;
  }

  /// Bağlı kullanıcının sıralama satırı; hiç alanı yoksa null.
  LeaderboardEntry? get myEntry {
    for (final e in leaderboard) {
      if (e.uid == _uid) return e;
    }
    return null;
  }

  /// Belirli bir kullanıcıya ait tüm alanların köşe noktaları (haritayı o
  /// kullanıcının topraklarına odaklamak için).
  List<LatLng> territoryPointsOf(String uid) => [
        for (final t in _territories)
          if (t.ownerUid == uid) ...t.points,
      ];

  /// Belirli bir kullanıcının elindeki toplam alan (metrekare).
  double areaOf(String uid) {
    var sum = 0.0;
    for (final t in _territories) {
      if (t.ownerUid == uid) sum += t.areaM2;
    }
    return sum;
  }

  /// Belirli bir kullanıcının haritada gösterilebilir (en az bir) alanı var mı?
  bool hasTerritory(String uid) =>
      _territories.any((t) => t.ownerUid == uid && t.points.length >= 3);

  /// Bağlı kullanıcının kendi alanlarının geometrisi (halka kapanma kontrolü
  /// için: koşu kendi alanından çıkıp kendi alanına dönerek de tamamlanabilir).
  List<TerritoryShape> get ownShapes => [
        for (final t in _territories)
          if (t.ownerUid == _uid && t.points.length >= 3)
            TerritoryShape(outer: t.points, holes: t.holes),
      ];

  /// Verilen koşu izinin fethedilebilir bir kapalı halka oluşturup
  /// oluşturmadığını döner. Hem koşu özeti (UI) hem de [claim] aynı kararı
  /// kullanır; böylece "alan aldın mı" göstergesi her zaman tutarlıdır.
  LoopResult checkLoop(List<LatLng> route) =>
      validateRunLoop(route: route, ownShapes: ownShapes);

  /// Tamamlanan turu kaydeder: yürüme geçmişine yazar ve döngü kapandıysa
  /// (alan oluştuysa) yeni alanı oluşturup çakışan rakip alanları fetheder.
  ///
  /// Alan adı kullanıcının tek [landName]'idir (her koşuda sorulmaz; Ayarlardan
  /// değiştirilir). Döngü kapanmadıysa yalnızca geçmişe kaydedilir, null döner.
  Future<ClaimOutcome?> claim({
    required List<LatLng> route,
    required double areaM2,
    required double distanceM,
    required Duration elapsed,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    // Yalnızca kapanmış bir halka alan oluşturur. Halka kapanmadıysa (başlangıca
    // ya da kendi alanına dönülmediyse) hiçbir yer fethedilmez; tur yine de
    // geçmişe yazılır.
    final loop = checkLoop(route);
    final polygon = loop.polygon;
    final canClaim = loop.valid && polygon.length >= 3;
    final effectiveName = landName;

    ClaimOutcome? outcome;
    if (canClaim) {
      outcome = await _fs.claimTerritory(
        uid: uid,
        username: _username,
        name: effectiveName,
        points: polygon,
        areaM2: planarAreaM2(polygon),
      );
    }

    await _fs.saveRun(
      uid: uid,
      run: RunRecord(
        id: '',
        distanceM: distanceM,
        durationSec: elapsed.inSeconds,
        areaM2: areaM2,
        route: route,
        claimedTerritory: canClaim,
        territoryName: canClaim ? effectiveName : null,
        conqueredCount: outcome?.conqueredCount ?? 0,
      ),
    );

    return outcome;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
