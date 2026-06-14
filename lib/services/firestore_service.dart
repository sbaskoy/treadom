import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/run_record.dart';
import '../models/territory.dart';

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
  /// (denormalize `name`) buna eşitler. `territories` istemciye salt-okunur
  /// olduğundan relabel SUNUCUDA (`renameLand` Cloud Function) yapılır.
  Future<void> updateLandName({
    required String uid,
    required String landName,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('renameLand');
    await callable.call(<String, dynamic>{'landName': landName.trim()});
  }

  /// Kullanıcının hesabını ve TÜM kişisel verilerini (topraklar, koşu geçmişi,
  /// sohbetler, kullanıcı dökümanı ve Auth hesabı) sunucuda kalıcı olarak siler.
  Future<void> deleteAccount() async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('deleteAccount');
    await callable.call();
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

  /// Kullanıcı dökümanını canlı yayınlar (kendi profilim/landName/denormalize
  /// toplamlar için).
  Stream<AppUser?> userStream(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  /// Liderlik tablosu: en yüksek toplam alana sahip kullanıcılar (denormalize
  /// `totalAreaM2`'den). Tüm `territories` taranmaz; tek-alan sıralaması
  /// otomatik indekslenir.
  Stream<List<AppUser>> topUsersStream({int limit = 50}) {
    return _users
        .orderBy('totalAreaM2', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromFirestore).toList());
  }

  /// Verilen alandan (m²) daha büyük toplam alana sahip kullanıcı SAYISINI
  /// döner (sıralama hesabı için; agregasyon sorgusu, doküman okumaz).
  Future<int> usersAboveArea(double areaM2) async {
    final agg = await _users
        .where('totalAreaM2', isGreaterThan: areaM2)
        .count()
        .get();
    return agg.count ?? 0;
  }

  // --- Alanlar (territories) ---

  /// Harita görünür alanındaki (viewport) alanları canlı yayınlar: merkezi
  /// (centroid) verilen sınır kutusu içinde olanlar. Tüm koleksiyonu indirmemek
  /// için; `territories` üzerinde (centroidLat, centroidLng) bileşik indeksi
  /// gerekir (firestore.indexes.json).
  Stream<List<Territory>> territoriesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    return _territories
        .where('centroidLat', isGreaterThanOrEqualTo: minLat)
        .where('centroidLat', isLessThanOrEqualTo: maxLat)
        .where('centroidLng', isGreaterThanOrEqualTo: minLng)
        .where('centroidLng', isLessThanOrEqualTo: maxLng)
        .snapshots()
        .map((snap) => snap.docs.map(Territory.fromFirestore).toList());
  }

  /// Kullanıcının KENDİ alanlarını canlı yayınlar (loop-closure geometrisi ve
  /// "kendi toprağım" için — viewport dışında bile gerekir). `ownerUid` tek-alan
  /// sorgusu otomatik indekslenir.
  Stream<List<Territory>> myTerritoriesStream(String uid) {
    return _territories
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Territory.fromFirestore).toList());
  }

  /// Belirli bir kullanıcının tüm alanlarını tek seferlik getirir (haritayı o
  /// kullanıcının topraklarına odaklamak için).
  Future<List<Territory>> territoriesOf(String uid) async {
    final snap =
        await _territories.where('ownerUid', isEqualTo: uid).get();
    return snap.docs.map(Territory.fromFirestore).toList();
  }

  /// Tamamlanan bir döngü için alan sahiplenme/fetih işlemini SUNUCUDA
  /// (`claimTerritory` Cloud Function) çalıştırır.
  ///
  /// Kısmi/tam fetih, rakip alanlara yazmayı ve tam fethedilen alanları silmeyi
  /// gerektirir; bunu admin yetkisiyle sunucu yapar, böylece `territories`
  /// koleksiyonu istemciye salt-okunur kalır (bkz. firestore.rules). Fethedilen
  /// kullanıcılara "bölgen ele geçirildi" push bildirimini de fonksiyon gönderir.
  ///
  /// İstemci yalnızca döngü noktalarını ve alan adını yollar. [uid]/[username]/
  /// [areaM2] sunucu tarafında oturumdan/geometriden türetildiği için
  /// kullanılmaz (çağrı imzası sağlayıcıyla uyumlu kalsın diye duruyor).
  Future<ClaimOutcome> claimTerritory({
    required String uid,
    required String username,
    required String name,
    required List<LatLng> points,
    required double areaM2,
    int durationSec = 0,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('claimTerritory');
    final res = await callable.call(<String, dynamic>{
      'name': name,
      'points': [
        for (final p in points) {'lat': p.latitude, 'lng': p.longitude},
      ],
      'durationSec': durationSec,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    final territoryId = (data['territoryId'] as String?) ?? '';
    final conqueredFrom = ((data['conqueredFrom'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    return ClaimOutcome(territoryId: territoryId, conqueredFrom: conqueredFrom);
  }

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
