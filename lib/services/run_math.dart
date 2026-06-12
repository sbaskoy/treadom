/// Koşu turuyla ilgili saf (yan etkisiz) hesap ve biçimleme yardımcıları.
///
/// Bu fonksiyonlar hem ön plandaki [RunProvider]'da (harita çizimi) hem de arka
/// plan izolatındaki koşu görevinde (bildirim metni) kullanılır. Tek kaynak
/// olmaları sayesinde iki taraf asla farklı sonuç üretmez.
library;

import 'dart:math';

import 'package:latlong2/latlong.dart';

/// İki coğrafi nokta arasındaki mesafeyi metre cinsinden döner.
double segmentMeters(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);

/// Rota noktalarından çevrelenen alanı metrekare cinsinden hesaplar.
///
/// Noktalar, ilk noktanın enlemine göre ölçeklenen eş dikdörtgensel
/// (equirectangular) izdüşümle metreye çevrilir; ardından kapalı çokgenin alanı
/// ayakkabı bağı (shoelace) formülüyle bulunur. Bir koşu turu kadar küçük
/// alanlar için yeterince doğrudur.
double planarAreaM2(List<LatLng> points) {
  if (points.length < 3) return 0;

  const earthRadius = 6378137.0; // WGS84 ekvator yarıçapı (m)
  final lat0 = points.first.latitudeInRad;
  final cosLat0 = cos(lat0);

  final xs = <double>[];
  final ys = <double>[];
  for (final p in points) {
    xs.add(earthRadius * p.longitudeInRad * cosLat0);
    ys.add(earthRadius * p.latitudeInRad);
  }

  double sum = 0;
  for (var i = 0; i < points.length; i++) {
    final j = (i + 1) % points.length;
    sum += xs[i] * ys[j] - xs[j] * ys[i];
  }
  return sum.abs() / 2;
}

/// Basit bir koşu kalori tahmini (kcal).
///
/// Koşuda yaklaşık olarak `1.036 × kilo(kg) × mesafe(km)` kadar enerji harcanır.
/// Kesinlik hedeflenmez; tempo/eğim gibi etkenler göz ardı edilir.
double estimateCalories({required double weightKg, required double distanceKm}) {
  return 1.036 * weightKg * distanceKm;
}

/// Ortalama tempoyu (kilometre başına süre) döner; mesafe çok kısaysa null.
Duration? pacePerKm(Duration elapsed, double distanceMeters) {
  if (distanceMeters < 20) return null; // anlamlı tempo için en az ~20 m
  final km = distanceMeters / 1000;
  final secondsPerKm = elapsed.inSeconds / km;
  return Duration(seconds: secondsPerKm.round());
}

/// Süreyi `MM:SS` (1 saatten azsa) ya da `H:MM:SS` biçiminde döner.
String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// Tempoyu `MM:SS` biçiminde döner (kilometre başına dakika:saniye).
String formatPace(Duration pace) {
  final m = pace.inMinutes;
  final s = pace.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
