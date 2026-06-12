import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Firestore'daki `users/{uid}/runs/{id}` dökümanını temsil eden, tamamlanmış
/// bir koşu/yürüyüş kaydı. Yürüme geçmişi ekranı bu kayıtları listeler.
class RunRecord {
  const RunRecord({
    required this.id,
    required this.distanceM,
    required this.durationSec,
    required this.areaM2,
    this.route = const [],
    this.createdAt,
    this.claimedTerritory = false,
    this.territoryName,
    this.conqueredCount = 0,
  });

  final String id;

  /// Katedilen toplam mesafe (metre).
  final double distanceM;

  /// Turun süresi (saniye).
  final int durationSec;

  /// Bu turda çevrelenen alan (metrekare); döngü kapanmadıysa 0.
  final double areaM2;

  /// Koşulan güzergah (rota noktaları). Geçmişte çizgi olarak gösterilir.
  final List<LatLng> route;

  /// Turun tamamlanma zamanı.
  final DateTime? createdAt;

  /// Bu turda bir alan sahiplenildi mi?
  final bool claimedTerritory;

  /// Sahiplenilen alanın adı (varsa).
  final String? territoryName;

  /// Bu turda fethedilen rakip alan sayısı.
  final int conqueredCount;

  Duration get duration => Duration(seconds: durationSec);

  factory RunRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return RunRecord(
      id: doc.id,
      distanceM: (data['distanceM'] as num?)?.toDouble() ?? 0,
      durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
      areaM2: (data['areaM2'] as num?)?.toDouble() ?? 0,
      route: ((data['path'] as List?) ?? const [])
          .whereType<GeoPoint>()
          .map((g) => LatLng(g.latitude, g.longitude))
          .toList(growable: false),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      claimedTerritory: (data['claimedTerritory'] as bool?) ?? false,
      territoryName: data['territoryName'] as String?,
      conqueredCount: (data['conqueredCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distanceM': distanceM,
      'durationSec': durationSec,
      'areaM2': areaM2,
      'path': route.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      'claimedTerritory': claimedTerritory,
      'territoryName': territoryName,
      'conqueredCount': conqueredCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
