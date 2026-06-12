import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Firestore'daki `territories/{id}` dökümanını temsil eden, harita üzerinde
/// çevrelenmiş ve sahiplenilmiş bir alan.
///
/// Bir kullanıcı kapalı bir döngü koşunca oluşur. Başka bir kullanıcı, bu
/// alanın merkezini içine alan daha büyük bir döngü koşarsa alanı fetheder;
/// bu durumda [ownerUid]/[ownerUsername] değişir ve [previousOwnerUsername]
/// dolar.
class Territory {
  const Territory({
    required this.id,
    required this.ownerUid,
    required this.ownerUsername,
    required this.name,
    required this.points,
    required this.areaM2,
    this.holes = const [],
    this.createdAt,
    this.previousOwnerUsername,
  });

  /// Firestore döküman kimliği.
  final String id;

  /// Alanı şu an elinde tutan kullanıcının kimliği.
  final String ownerUid;

  /// Sahibin görünen kullanıcı adı (harita etiketinde gösterilir).
  final String ownerUsername;

  /// Kullanıcının verdiği alan adı (boş bırakılırsa kullanıcı adı kullanılır).
  final String name;

  /// Alanı çevreleyen dış çokgenin köşeleri.
  final List<LatLng> points;

  /// Alanın içindeki delikler (kısmi fetihte oyulan iç bölgeler). Her biri
  /// kapalı bir halkadır. Çoğu alanda boştur.
  final List<List<LatLng>> holes;

  /// Alanın büyüklüğü (metrekare).
  final double areaM2;

  /// Alanın ilk oluşturulma zamanı.
  final DateTime? createdAt;

  /// Bu alan bir başkasından fethedildiyse, önceki sahibin adı.
  final String? previousOwnerUsername;

  /// Alanın merkez etiketinde gösterilecek isim (isim boşsa kullanıcı adı).
  String get displayName => name.trim().isEmpty ? ownerUsername : name.trim();

  factory Territory.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Territory(
      id: doc.id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      ownerUsername: (data['ownerUsername'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      points: _ring(data['points']),
      holes: ((data['holes'] as List?) ?? const [])
          .whereType<Map>()
          .map((h) => _ring(h['points']))
          .where((r) => r.length >= 3)
          .toList(growable: false),
      areaM2: (data['areaM2'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      previousOwnerUsername: data['previousOwnerUsername'] as String?,
    );
  }

  /// Firestore'daki bir GeoPoint dizisini LatLng halkasına çevirir.
  static List<LatLng> _ring(Object? raw) {
    return ((raw as List?) ?? const [])
        .whereType<GeoPoint>()
        .map((g) => LatLng(g.latitude, g.longitude))
        .toList(growable: false);
  }
}
