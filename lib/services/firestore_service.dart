import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/run_record.dart';
import '../models/territory.dart';
import 'geo.dart';
import 'run_math.dart' show planarAreaM2;

/// Bir turun fethedilen alan sahiplenme işleminin sonucu.
class ClaimOutcome {
  const ClaimOutcome({
    required this.territoryId,
    required this.conqueredFrom,
  });

  /// Yeni oluşturulan alanın kimliği.
  final String territoryId;

  /// Bu turda fethedilen rakip alanların önceki sahiplerinin adları.
  final List<String> conqueredFrom;

  int get conqueredCount => conqueredFrom.length;
}

/// Cloud Firestore okuma/yazma işlemlerini tek bir yerde toplayan servis.
///
/// Kullanıcı dökümanlarının yanı sıra fethedilen alanları (`territories`) ve
/// kullanıcı başına yürüme geçmişini (`users/{uid}/runs`) yönetir.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// `users` koleksiyonuna tipli erişim.
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Tüm fethedilen alanları tutan global koleksiyon.
  CollectionReference<Map<String, dynamic>> get _territories =>
      _db.collection('territories');

  /// Belirli bir kullanıcının yürüme geçmişi alt-koleksiyonu.
  CollectionReference<Map<String, dynamic>> _runs(String uid) =>
      _users.doc(uid).collection('runs');

  // --- Kullanıcılar ---

  /// Yeni kayıt olan kullanıcı için `users/{uid}` dökümanını oluşturur.
  Future<void> createUser({
    required String uid,
    required String username,
  }) {
    // Varsayılan alan adı = kullanıcı adı (kullanıcı ayarlardan değiştirebilir).
    final user = AppUser(uid: uid, username: username, landName: username);
    return _users.doc(uid).set(user.toFirestore());
  }

  /// Kullanıcının tek alan adını günceller ve mevcut TÜM alanlarının etiketini
  /// (denormalize `name`) buna eşitler — böylece haritada tutarlı görünür.
  Future<void> updateLandName({
    required String uid,
    required String landName,
  }) async {
    final trimmed = landName.trim();
    final batch = _db.batch();
    batch.update(_users.doc(uid), {'landName': trimmed});

    final mine = await _territories.where('ownerUid', isEqualTo: uid).get();
    for (final doc in mine.docs) {
      final label =
          trimmed.isEmpty ? (doc.data()['ownerUsername'] as String? ?? '') : trimmed;
      batch.update(doc.reference, {'name': label});
    }
    await batch.commit();
  }

  /// Belirli bir kullanıcının dökümanını getirir (yoksa null).
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Kullanıcı adının baş kısmına göre kullanıcı arar (büyük/küçük harf
  /// duyarsız; adlar Firestore'da küçük harfle saklanır). Boş sorguda boş
  /// liste döner.
  ///
  /// Tek alan üzerinde aralık sorgusu olduğu için ek (composite) indeks
  /// gerektirmez. Sonuç [limit] ile sınırlanır.
  Future<List<AppUser>> searchUsersByUsername(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final snap = await _users
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThan: '$q')
        .limit(limit)
        .get();
    return snap.docs.map(AppUser.fromFirestore).toList();
  }

  // --- Alanlar (territories) ---

  /// Tüm alanları canlı yayınlar (harita üzerinde herkesin alanını çizmek için).
  Stream<List<Territory>> territoriesStream() {
    return _territories.snapshots().map(
          (snap) => snap.docs.map(Territory.fromFirestore).toList(),
        );
  }

  /// Tamamlanan bir döngü için yeni bir alan oluşturur ve aynı işlemde, döngünün
  /// kapladığı rakip alan parçalarını fetheder (KISMİ fetih).
  ///
  /// Kural: rakip alandan, benim döngümün kapladığı bölge çıkarılır (boolean
  /// difference). Geri kalan rakipte kalır; benim yeni alanım ise döngünün
  /// tamamıdır (çakışma bölgesi dahil) — böylece çift sayım olmaz.
  ///   - Rakip alan döngümle TAMAMEN kapanırsa silinir; o bölge artık yalnızca
  ///     benim tek alanım olarak (kendi adımla) görünür.
  ///   - Kısmen çakışırsa rakip alan küçülür (adı/sahibi korunur); döngü onu
  ///     ikiye böldüyse kalan her parça ayrı bir alan olur.
  ///
  /// Tüm alanlar okunur, kesişimler istemcide [polygonDifference] ile hesaplanır
  /// ve yazımlar tek bir toplu işlemle (batch) uygulanır. Bu, rakibe ait
  /// dökümanlara yazmayı gerektirdiğinden güvenlik kuralları gevşetilmiştir
  /// (bkz. firestore.rules — prototip; üretimde Cloud Function'a taşınmalı).
  Future<ClaimOutcome> claimTerritory({
    required String uid,
    required String username,
    required String name,
    required List<LatLng> points,
    required double areaM2,
  }) async {
    final batch = _db.batch();
    final loopBox = _Box.of(points);
    final existing = await _territories.get();

    // Yeni döngüyle başla; kendi (çakışan) alanlarımı buna katıp TEK polygon
    // yapacağım. Böylece bir kişide üst üste binen iki ayrı polygon kalmaz.
    final mine = <TerritoryShape>[TerritoryShape(outer: points)];
    final ownToDelete = <DocumentReference<Map<String, dynamic>>>[];
    final conqueredFrom = <String>[];

    for (final doc in existing.docs) {
      final data = doc.data();
      final isOwn = (data['ownerUid'] as String?) == uid;

      final otherOuter = _ringFrom(data['points']);
      if (otherOuter.length < 3) continue;
      // Hızlı eleme: sınır kutuları kesişmiyorsa kesinlikle çakışma yok.
      if (!loopBox.overlaps(_Box.of(otherOuter))) continue;

      final otherHoles = ((data['holes'] as List?) ?? const [])
          .whereType<Map>()
          .map((h) => _ringFrom(h['points']))
          .where((r) => r.length >= 3)
          .toList();

      final shapes = polygonDifference(
        subjectOuter: otherOuter,
        subjectHoles: otherHoles,
        clip: points,
      );
      final origArea = (data['areaM2'] as num?)?.toDouble() ??
          planarAreaM2(otherOuter);
      final remaining = shapes.fold<double>(0, (a, s) => a + shapeAreaM2(s));
      if ((origArea - remaining).abs() < 0.5) continue; // çakışma yok → dokunma

      if (isOwn) {
        // Kendi alanım: yeni döngüyle birleştirilecek (tek polygon). Eski
        // dökümanını sileceğiz.
        mine.add(TerritoryShape(outer: otherOuter, holes: otherHoles));
        ownToDelete.add(doc.reference);
        continue;
      }

      // Rakip alan: kısmi/tam fetih.
      conqueredFrom.add((data['ownerUsername'] as String?) ?? '');
      if (shapes.isEmpty) {
        batch.delete(doc.reference); // tamamen fethedildi → sil
        continue;
      }
      // Kalan ilk parça mevcut dökümanı günceller (rakip sahip/ad korunur).
      batch.update(doc.reference, {
        'points': _geoPoints(shapes.first.outer),
        'holes': _holesField(shapes.first.holes),
        'areaM2': shapeAreaM2(shapes.first),
      });
      // Döngü alanı böldüyse, ek parçalar aynı rakibe ait yeni alanlar olur.
      for (var i = 1; i < shapes.length; i++) {
        final extraRef = _territories.doc();
        batch.set(extraRef, _territoryData(
          ownerUid: (data['ownerUid'] as String?) ?? '',
          ownerUsername: (data['ownerUsername'] as String?) ?? '',
          name: (data['name'] as String?) ?? '',
          outer: shapes[i].outer,
          holes: shapes[i].holes,
          areaM2: shapeAreaM2(shapes[i]),
          createdAt: data['createdAt'],
        ));
      }
    }

    // Kendi (çakışan) alanlarımı yeni döngüyle birleştir → tek polygon, eskileri
    // sil.
    for (final ref in ownToDelete) {
      batch.delete(ref);
    }
    final merged = mine.length == 1 ? mine : polygonUnion(mine);
    String? firstId;
    for (final shape in merged) {
      final ref = _territories.doc();
      firstId ??= ref.id;
      batch.set(ref, _territoryData(
        ownerUid: uid,
        ownerUsername: username,
        name: name,
        outer: shape.outer,
        holes: shape.holes,
        areaM2: shapeAreaM2(shape),
      ));
    }

    await batch.commit();
    return ClaimOutcome(territoryId: firstId ?? '', conqueredFrom: conqueredFrom);
  }

  // Firestore serileştirme yardımcıları.

  List<GeoPoint> _geoPoints(List<LatLng> ring) =>
      ring.map((p) => GeoPoint(p.latitude, p.longitude)).toList();

  /// Delikler iç içe dizi olarak saklanamaz; her biri {points:[...]} haritasıdır.
  List<Map<String, dynamic>> _holesField(List<List<LatLng>> holes) =>
      holes.map((h) => {'points': _geoPoints(h)}).toList();

  Map<String, dynamic> _territoryData({
    required String ownerUid,
    required String ownerUsername,
    required String name,
    required List<LatLng> outer,
    required double areaM2,
    List<List<LatLng>> holes = const [],
    Object? createdAt,
  }) {
    return {
      'ownerUid': ownerUid,
      'ownerUsername': ownerUsername,
      'name': name,
      'points': _geoPoints(outer),
      'holes': _holesField(holes),
      'areaM2': areaM2,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'previousOwnerUsername': null,
    };
  }

  static List<LatLng> _ringFrom(Object? raw) =>
      ((raw as List?) ?? const [])
          .whereType<GeoPoint>()
          .map((g) => LatLng(g.latitude, g.longitude))
          .toList();

  // --- Yürüme geçmişi (runs) ---

  /// Tamamlanmış bir turu kullanıcının geçmişine kaydeder.
  Future<void> saveRun({
    required String uid,
    required RunRecord run,
  }) {
    return _runs(uid).add(run.toFirestore());
  }

  /// Kullanıcının yürüme geçmişini en yeniden eskiye doğru yayınlar.
  Stream<List<RunRecord>> userRunsStream(String uid) {
    return _runs(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RunRecord.fromFirestore).toList());
  }
}

/// Hızlı çakışma elemesi için basit bir enlem/boylam sınır kutusu.
class _Box {
  const _Box(this.minLat, this.minLng, this.maxLat, this.maxLng);

  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  factory _Box.of(List<LatLng> ring) {
    var minLat = double.infinity, minLng = double.infinity;
    var maxLat = -double.infinity, maxLng = -double.infinity;
    for (final p in ring) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return _Box(minLat, minLng, maxLat, maxLng);
  }

  bool overlaps(_Box o) =>
      minLat <= o.maxLat &&
      maxLat >= o.minLat &&
      minLng <= o.maxLng &&
      maxLng >= o.minLng;
}
