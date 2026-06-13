import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
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

/// Harita üzerindeki alanları (kendi + görünür alan), sıralamayı ve fetih
/// işlemini yöneten sağlayıcı.
///
/// ÖLÇEK: Artık tüm `territories` koleksiyonu indirilmez. Üç kaynak ayrı ayrı
/// izlenir:
///   - **Kendi alanlarım** (`myTerritoriesStream`): loop-closure geometrisi ve
///     "kendi toprağım" için (viewport dışında bile gerekir).
///   - **Görünür alan** (`territoriesInBounds`): haritada çizilecek rakip+kendi
///     alanlar; harita kaydıkça [setViewport] ile güncellenir.
///   - **Liderlik tablosu** (`topUsersStream`): denormalize `users.totalAreaM2`
///     üzerinden; tüm alanlar taranmaz.
class TerritoryProvider extends ChangeNotifier {
  TerritoryProvider({FirestoreService? firestore})
      : _fs = firestore ?? FirestoreService();

  final FirestoreService _fs;

  StreamSubscription<AppUser?>? _meSub;
  StreamSubscription<List<Territory>>? _mySub;
  StreamSubscription<List<Territory>>? _viewSub;
  StreamSubscription<List<AppUser>>? _lbSub;

  String? _uid;
  String _username = '';
  String _landName = '';

  List<Territory> _myTerritories = const [];
  List<Territory> _viewTerritories = const [];
  List<LeaderboardEntry> _leaderboard = const [];
  LeaderboardEntry? _myEntry;
  int? _myRank;

  // Viewport sorgusu için debounce + son uygulanan kutu (gereksiz yeniden
  // aboneliği önlemek için).
  Timer? _viewDebounce;
  _Bounds? _lastViewBounds;

  /// Şu an bağlı kullanıcının görünen adı (alan adı boş bırakılınca kullanılır).
  String get username => _username;

  /// Kullanıcının tek alan adı (boşsa kullanıcı adına düşer).
  String get landName =>
      _landName.trim().isEmpty ? _username : _landName.trim();

  /// Bağlı kullanıcının kimliği.
  String? get uid => _uid;

  /// Haritada çizilecek alanlar: görünür alan ∪ kendi alanlarım (kimliğe göre
  /// tekilleştirilir; böylece kendi toprağım viewport dışındayken de görünür).
  List<Territory> get territories {
    final byId = <String, Territory>{};
    for (final t in _viewTerritories) {
      byId[t.id] = t;
    }
    for (final t in _myTerritories) {
      byId[t.id] = t;
    }
    return byId.values.toList();
  }

  /// Liderlik tablosu (denormalize toplamlara göre, azalan).
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  /// Bağlı kullanıcının sıralamadaki yeri (1 tabanlı); hiç alanı yoksa null.
  int? get myRank => _myRank;

  /// Bağlı kullanıcının sıralama satırı; hiç alanı yoksa null.
  LeaderboardEntry? get myEntry => _myEntry;

  /// Sağlayıcıyı oturum açan kullanıcıya bağlar.
  Future<void> bind(String uid) async {
    if (_uid == uid) return;
    _uid = uid;

    // Anlık kullanım için adı/landName'i bir kez yükle; akış ayrıca canlı tutar.
    final user = await _fs.getUser(uid);
    _username = user?.username ?? '';
    _landName = user?.landName ?? '';

    await _meSub?.cancel();
    _meSub = _fs.userStream(uid).listen((u) {
      if (u == null) return;
      _username = u.username;
      _landName = u.landName;
      _myEntry = u.totalAreaM2 > 0
          ? LeaderboardEntry(
              uid: uid,
              username: u.username,
              areaM2: u.totalAreaM2,
              territoryCount: u.territoryCount,
            )
          : null;
      _refreshMyRank();
      notifyListeners();
    });

    await _mySub?.cancel();
    _mySub = _fs.myTerritoriesStream(uid).listen((list) {
      _myTerritories = list;
      notifyListeners();
    });

    await _lbSub?.cancel();
    _lbSub = _fs.topUsersStream().listen((users) {
      _leaderboard = [
        for (final u in users)
          if (u.totalAreaM2 > 0)
            LeaderboardEntry(
              uid: u.uid,
              username: u.username,
              areaM2: u.totalAreaM2,
              territoryCount: u.territoryCount,
            ),
      ];
      notifyListeners();
    });

    notifyListeners();
  }

  /// Bağlı kullanıcının sıralamasını (kendinden daha büyük alanı olanların
  /// sayısı + 1) agregasyon sorgusuyla tazeler. Alanı yoksa null.
  Future<void> _refreshMyRank() async {
    final area = _myEntry?.areaM2 ?? 0;
    if (area <= 0) {
      _myRank = null;
      return;
    }
    try {
      final above = await _fs.usersAboveArea(area);
      _myRank = above + 1;
      notifyListeners();
    } catch (_) {
      // Sıra hesaplanamazsa göstergeyi bozma.
    }
  }

  /// Harita görünür alanını (viewport) ayarlar; alanları o kutuya sınırlar.
  /// Hızlı kaydırmalarda gereksiz sorguyu önlemek için debounce uygulanır ve
  /// kutu, kenar alanları da yakalamak için biraz genişletilir.
  void setViewport({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    // ~%30 marj (kenardaki ve merkezi kutu dışına taşan alanlar için).
    final latPad = (maxLat - minLat) * 0.3;
    final lngPad = (maxLng - minLng) * 0.3;
    final b = _Bounds(
      minLat - latPad,
      maxLat + latPad,
      minLng - lngPad,
      maxLng + lngPad,
    );
    if (_lastViewBounds != null && _lastViewBounds!.approxEquals(b)) return;

    _viewDebounce?.cancel();
    _viewDebounce = Timer(const Duration(milliseconds: 350), () {
      _lastViewBounds = b;
      _viewSub?.cancel();
      _viewSub = _fs
          .territoriesInBounds(
            minLat: b.minLat,
            maxLat: b.maxLat,
            minLng: b.minLng,
            maxLng: b.maxLng,
          )
          .listen((list) {
        _viewTerritories = list;
        notifyListeners();
      });
    });
  }

  /// Kullanıcının tek alan adını değiştirir (Ayarlar'dan); sunucu mevcut tüm
  /// alanlarının etiketini de günceller.
  Future<void> setLandName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await _fs.updateLandName(uid: uid, landName: name);
    _landName = name.trim();
    notifyListeners();
  }

  /// Bir alanın bağlı kullanıcıya ait olup olmadığını döner.
  bool isMine(Territory t) => t.ownerUid == _uid;

  /// Belirli bir kullanıcının alanlarının köşe noktalarını (haritayı o
  /// kullanıcının topraklarına odaklamak için) tek seferlik getirir.
  Future<List<LatLng>> pointsOf(String uid) async {
    final list = await _fs.territoriesOf(uid);
    return [for (final t in list) ...t.points];
  }

  /// Bağlı kullanıcının kendi alanlarının geometrisi (halka kapanma kontrolü
  /// için).
  List<TerritoryShape> get ownShapes => [
        for (final t in _myTerritories)
          if (t.points.length >= 3)
            TerritoryShape(outer: t.points, holes: t.holes),
      ];

  /// Verilen koşu izinin fethedilebilir bir kapalı halka oluşturup
  /// oluşturmadığını döner.
  LoopResult checkLoop(List<LatLng> route) =>
      validateRunLoop(route: route, ownShapes: ownShapes);

  /// Tamamlanan turu kaydeder: yürüme geçmişine yazar ve döngü kapandıysa
  /// (alan oluştuysa) sunucuda yeni alanı oluşturup çakışan rakip alanları
  /// fetheder.
  Future<ClaimOutcome?> claim({
    required List<LatLng> route,
    required double areaM2,
    required double distanceM,
    required Duration elapsed,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

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
    _viewDebounce?.cancel();
    _meSub?.cancel();
    _mySub?.cancel();
    _viewSub?.cancel();
    _lbSub?.cancel();
    super.dispose();
  }
}

/// Viewport sorgusu için basit bir enlem/boylam sınır kutusu.
class _Bounds {
  const _Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  /// İki kutu, küçük bir toleransla (yaklaşık ~birkaç metre) aynı mı? Aynıysa
  /// yeniden sorgu açmayız.
  bool approxEquals(_Bounds o) {
    const eps = 0.0005; // ~50 m
    return (minLat - o.minLat).abs() < eps &&
        (maxLat - o.maxLat).abs() < eps &&
        (minLng - o.minLng).abs() < eps &&
        (maxLng - o.maxLng).abs() < eps;
  }
}
