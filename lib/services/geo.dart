/// Çokgen (polygon) ile ilgili saf (yan etkisiz) geometri yardımcıları.
///
/// Fethetme mantığı bu fonksiyonlara dayanır: bir kullanıcının yeni kapattığı
/// alan, başka bir kullanıcının alanının merkezini içine alıyorsa o alanı
/// fetheder. Küçük koşu alanları için düzlemsel (enlem/boylam) yaklaşımı
/// yeterince doğrudur.
library;

import 'dart:math';

import 'package:clipper2/clipper2.dart';
import 'package:latlong2/latlong.dart';

import 'run_math.dart' show planarAreaM2, segmentMeters;

/// Tek bir alan parçasının geometrisi: bir dış halka ve (varsa) içindeki
/// delikler. Kısmi fetih sonrası bir alan birden çok parçaya bölünebilir ya da
/// ortasında delik (fethedilen iç bölge) oluşabilir.
class TerritoryShape {
  const TerritoryShape({required this.outer, this.holes = const []});

  final List<LatLng> outer;
  final List<List<LatLng>> holes;
}

/// Bir alan parçasının net alanı (dış halka eksi delikler), metrekare.
double shapeAreaM2(TerritoryShape shape) {
  var area = planarAreaM2(shape.outer);
  for (final h in shape.holes) {
    area -= planarAreaM2(h);
  }
  return area < 0 ? 0 : area;
}

/// [subjectOuter] (+ varsa [subjectHoles]) çokgeninden, kapalı [clip] döngüsünü
/// çıkarır (boolean difference). Sonuç, her biri dış halka + delikleri olan
/// parça listesidir; [clip] subject'i tamamen kapsıyorsa boş liste döner.
///
/// Kısmi fetihin temelidir: rakip alandan, benim koştuğum döngünün kapladığı
/// bölge çıkarılır; geri kalanı rakipte kalır. Sağlam (tamsayıya ölçekleyen)
/// Clipper2 algoritması, ortak kenarlı kareler gibi dejenere durumları da düzgün
/// işler.
List<TerritoryShape> polygonDifference({
  required List<LatLng> subjectOuter,
  List<List<LatLng>> subjectHoles = const [],
  required List<LatLng> clip,
}) {
  final subject = <PathD>[
    _ringToPath(subjectOuter),
    for (final h in subjectHoles) _ringToPath(h),
  ];
  final result = Clipper.differenceD(
    subject: subject,
    clip: <PathD>[_ringToPath(clip)],
    fillRule: FillRule.nonZero,
    precision: 8, // ~1 mm enlem/boylam çözünürlüğü (Clipper2 üst sınırı)
  );
  return _classifyShapes(result);
}

/// Birden çok alan parçasını TEK geometride birleştirir (boolean union).
///
/// Kullanıcı kendi alanının içinde/üstünde koşunca, yeni döngüyü mevcut
/// alanlarıyla birleştirip tek polygon yapmak için kullanılır — böylece bir
/// kişide üst üste binen iki ayrı polygon kalmaz. Sonuç birden çok parça
/// (ayrık alanlar) ya da delikli olabilir.
List<TerritoryShape> polygonUnion(List<TerritoryShape> shapes) {
  if (shapes.isEmpty) return const [];
  final subject = <PathD>[];
  for (final s in shapes) {
    subject.add(_ringToPath(s.outer));
    for (final h in s.holes) {
      subject.add(_ringToPath(h));
    }
  }
  final result = Clipper.unionD(
    subject: subject,
    clip: const <PathD>[],
    fillRule: FillRule.nonZero,
    precision: 8,
  );
  return _classifyShapes(result);
}

PathD _ringToPath(List<LatLng> r) =>
    [for (final p in r) PointD(p.longitude, p.latitude)];

List<LatLng> _pathToRing(PathD p) => [for (final pt in p) LatLng(pt.y, pt.x)];

/// Clipper2 sonucundaki halkaları (pozitif alan = dış halka, negatif = delik)
/// parçalara ayırır ve her deliği onu içeren dış halkaya atar.
List<TerritoryShape> _classifyShapes(PathsD result) {
  final outers = <PathD>[];
  final holes = <PathD>[];
  for (final path in result) {
    if (path.length < 3) continue;
    (path.isPositive ? outers : holes).add(path);
  }

  final shapes = <TerritoryShape>[];
  for (final o in outers) {
    final outerLatLng = _pathToRing(o);
    final assigned = <List<LatLng>>[];
    for (final h in holes) {
      if (pointInPolygon(LatLng(h.first.y, h.first.x), outerLatLng)) {
        assigned.add(_pathToRing(h));
      }
    }
    shapes.add(TerritoryShape(outer: outerLatLng, holes: assigned));
  }
  return shapes;
}

/// Çokgenin alan-ağırlıklı merkezini (centroid) döner.
///
/// Standart çokgen centroid formülü kullanılır. Alan sıfıra çok yakınsa
/// (dejenere/çizgisel rota) köşelerin basit ortalamasına düşer.
LatLng polygonCentroid(List<LatLng> points) {
  if (points.isEmpty) {
    throw ArgumentError('Boş çokgenin merkezi hesaplanamaz.');
  }
  if (points.length < 3) {
    return _vertexAverage(points);
  }

  double area2 = 0; // imzalı alanın iki katı
  double cx = 0;
  double cy = 0;
  for (var i = 0; i < points.length; i++) {
    final p0 = points[i];
    final p1 = points[(i + 1) % points.length];
    final cross = p0.longitude * p1.latitude - p1.longitude * p0.latitude;
    area2 += cross;
    cx += (p0.longitude + p1.longitude) * cross;
    cy += (p0.latitude + p1.latitude) * cross;
  }

  if (area2.abs() < 1e-12) {
    return _vertexAverage(points);
  }

  final lon = cx / (3 * area2);
  final lat = cy / (3 * area2);
  return LatLng(lat, lon);
}

LatLng _vertexAverage(List<LatLng> points) {
  double lat = 0;
  double lon = 0;
  for (final p in points) {
    lat += p.latitude;
    lon += p.longitude;
  }
  return LatLng(lat / points.length, lon / points.length);
}

/// [inner] çokgeninin TAMAMEN [outer] çokgeninin içinde olup olmadığını döner.
///
/// "Bir alanın etrafını tam dolanmak" = o alanın bütün köşelerini çevrelemek.
/// Fethetme yalnızca bu koşulda olur: rakip alanın içine girmek ya da bir
/// kısmını kesmek yeterli değildir; alanı tamamen kuşatmak gerekir.
bool polygonFullyContains(List<LatLng> outer, List<LatLng> inner) {
  if (outer.length < 3 || inner.isEmpty) return false;
  for (final p in inner) {
    if (!pointInPolygon(p, outer)) return false;
  }
  return true;
}

/// Bir noktanın bir alanın (dış halka + delikler) içinde olup olmadığını döner:
/// dış halkanın içinde ama hiçbir deliğin içinde değilse `true`. Haritada bir
/// alana dokunulduğunda hangi alanın seçildiğini bulmak için kullanılır.
bool pointInShape(LatLng point, List<LatLng> outer, List<List<LatLng>> holes) {
  if (!pointInPolygon(point, outer)) return false;
  for (final h in holes) {
    if (pointInPolygon(point, h)) return false;
  }
  return true;
}

/// Bir noktanın bir alana (dış halka + delikler) en kısa mesafesi (metre).
/// Nokta alanın içindeyse 0 döner. Koşunun "kendi alanına döndü mü" kararında,
/// GPS sapmasına tolerans için bir kenar payı (margin) ile birlikte kullanılır.
double distanceToShapeM(LatLng p, TerritoryShape shape) {
  if (pointInShape(p, shape.outer, shape.holes)) return 0;
  var best = double.infinity;
  for (final ring in [shape.outer, ...shape.holes]) {
    if (ring.length < 2) continue;
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      final d = _distPointToSegmentM(p, a, b);
      if (d < best) best = d;
    }
  }
  return best;
}

/// Bir noktanın bir doğru parçasına (a-b) düzlemsel mesafesi (metre). Küçük
/// alanlar için yeterli olan eş dikdörtgensel (equirectangular) izdüşüm kullanılır.
double _distPointToSegmentM(LatLng p, LatLng a, LatLng b) {
  const r = 6378137.0; // WGS84 ekvator yarıçapı (m)
  final cosLat = cos(p.latitudeInRad);
  double px = r * p.longitudeInRad * cosLat, py = r * p.latitudeInRad;
  double ax = r * a.longitudeInRad * cosLat, ay = r * a.latitudeInRad;
  double bx = r * b.longitudeInRad * cosLat, by = r * b.latitudeInRad;

  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  return sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}

/// Oyunda kabul edilen azami hareket hızı (m/s). ~20 km/h: en hızlı koşucuyu
/// rahat geçirir ama bisiklet/araba bunun üzerindedir. Bunu aşan turlar alan
/// kazandırmaz ("yürüyerek/koşarak oyna" kuralı). GPS gürültüsüne karşı
/// istemcide kısa pencere ortalamasıyla kullanılır.
const double kMaxRunSpeedMps = 5.56;

/// Geçmişe kaydedilmesi için (fetih yoksa) bir turun en az kat etmesi gereken
/// mesafe (metre). 25 m, yerinde dururkenki GPS sapmasını güvenle eler ama
/// gerçek kısa yürüyüşü korur. Hareketin gerçek sinyali mesafedir (süre değil:
/// yerinde uzun durmak da, hızlı kısa koşmak da süreyle ayırt edilemez).
const double kMinSavedRunMeters = 25;

/// Koşunun neden alan oluşturmadığını açıklar (kullanıcıya geri bildirim için).
enum LoopFailReason {
  /// Geçerli bir döngü oluştu.
  none,

  /// Çok kısa: yeterince uzağa gidip dönülmedi.
  tooShort,

  /// Halka kapanmadı: başlangıca (ya da kendi alanına) geri dönülmedi.
  notClosed,

  /// Çok hızlı: araç hızında hareket algılandı (yürüyüş/koşu değil).
  tooFast,
}

/// Bir koşu izinin (route) fethedilebilir bir kapalı halka oluşturup
/// oluşturmadığının sonucu.
class LoopResult {
  const LoopResult({
    required this.valid,
    this.polygon = const [],
    this.reason = LoopFailReason.none,
  });

  /// Geçerli (kapanmış) bir döngü mü?
  final bool valid;

  /// Fethedilecek kapalı çokgen (geçersizse boş).
  final List<LatLng> polygon;

  /// Geçersizse nedeni.
  final LoopFailReason reason;
}

/// Bir koşu izinin alan sahiplenmek için geçerli bir kapalı halka oluşturup
/// oluşturmadığını değerlendirir (splix.io tarzı "iz kapatma" mekaniği).
///
/// Kurallar:
/// - İz, anlamlı bir uzunluğa ([minLoopMeters]) ulaşmalıdır ("önce belli bir
///   süre git").
/// - Koşu KENDİ alanının üstünde/yakınında ([territoryMarginM]) başladıysa,
///   halka ancak iz dışarı çıkıp tekrar KENDİ alanına dönerse kapanır. Dışarıda
///   kendi alanına dönmeden atılan bir tur fetih SAYILMAZ.
/// - Aksi halde (henüz alanı yoksa ya da alanından uzakta başladıysa) halka,
///   izin sonu başlangıç noktasına [closeThresholdM] kadar yaklaşınca kapanır.
LoopResult validateRunLoop({
  required List<LatLng> route,
  required List<TerritoryShape> ownShapes,
  double closeThresholdM = 35,
  double minLoopMeters = 50,
  double territoryMarginM = 20,
  double minAreaM2 = 100,
}) {
  if (route.length < 4) {
    return const LoopResult(valid: false, reason: LoopFailReason.tooShort);
  }

  var length = 0.0;
  for (var i = 1; i < route.length; i++) {
    length += segmentMeters(route[i - 1], route[i]);
  }
  if (length < minLoopMeters) {
    return const LoopResult(valid: false, reason: LoopFailReason.tooShort);
  }

  final start = route.first;
  final end = route.last;

  // Koşu kendi alanının üstünde mi başladı?
  final startedOnOwn =
      ownShapes.any((s) => distanceToShapeM(start, s) <= territoryMarginM);

  if (startedOnOwn) {
    // Kendi alanından çıkıp tekrar kendi alanına dönülmeli.
    final returnedHome =
        ownShapes.any((s) => distanceToShapeM(end, s) <= territoryMarginM);
    if (!returnedHome) {
      return const LoopResult(valid: false, reason: LoopFailReason.notClosed);
    }
    // Gerçekten dışarı çıkıldı mı? (Tümüyle kendi alanında kalan tur yeni alan
    // sayılmaz.) En az bir nokta tüm kendi alanlarının dışında olmalı.
    final wentOut = route.any(
      (p) => ownShapes.every((s) => distanceToShapeM(p, s) > territoryMarginM),
    );
    if (!wentOut) {
      return const LoopResult(valid: false, reason: LoopFailReason.notClosed);
    }
    return _acceptIfEncloses(route, minAreaM2);
  }

  // Alan çapası yok: izin sonu başlangıca yaklaşmalı.
  if (segmentMeters(start, end) <= closeThresholdM) {
    return _acceptIfEncloses(route, minAreaM2);
  }
  return const LoopResult(valid: false, reason: LoopFailReason.notClosed);
}

/// Halka "kapandı" sayılsa bile anlamlı bir alan çevrelemeli. Aynı çizgide
/// gidip dönmek (başlangıca yakın biten ama ~0 m² kapsayan ince iz) fetih
/// SAYILMAZ — aksi halde düz bir koşu sıfır alanlı bir "alan" oluştururdu.
LoopResult _acceptIfEncloses(List<LatLng> route, double minAreaM2) {
  if (planarAreaM2(route) < minAreaM2) {
    return const LoopResult(valid: false, reason: LoopFailReason.notClosed);
  }
  return LoopResult(valid: true, polygon: List<LatLng>.from(route));
}

/// Bir noktanın çokgenin içinde olup olmadığını ışın atma (ray casting)
/// yöntemiyle döner. Kenar üzerindeki noktalar için sonuç belirsiz olabilir;
/// fethetme kararı için bu yeterlidir.
bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return false;

  final x = point.longitude;
  final y = point.latitude;
  var inside = false;

  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].longitude, yi = polygon[i].latitude;
    final xj = polygon[j].longitude, yj = polygon[j].latitude;

    final intersects = ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
    if (intersects) inside = !inside;
  }
  return inside;
}
