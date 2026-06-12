// run_math.dart içindeki saf hesap/biçimleme fonksiyonlarının birim testleri.
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:treadom/services/run_math.dart';

void main() {
  group('segmentMeters', () {
    test('0.001 derece enlem farkı ~111 m verir', () {
      final d = segmentMeters(const LatLng(0, 0), const LatLng(0.001, 0));
      expect(d, closeTo(111.3, 1.0));
    });
  });

  group('planarAreaM2', () {
    test('3 noktadan az ise 0 döner', () {
      expect(planarAreaM2([const LatLng(0, 0), const LatLng(0, 0.001)]), 0);
    });

    test('küçük bir kare için makul alan hesaplar', () {
      // Ekvatorda ~100 m × ~100 m kareye yakın bir döngü.
      const d = 0.0009; // ~100 m
      final area = planarAreaM2(const [
        LatLng(0, 0),
        LatLng(0, d),
        LatLng(d, d),
        LatLng(d, 0),
      ]);
      // ~100 m kenar → ~10.000 m²; geniş tolerans.
      expect(area, closeTo(10000, 1500));
    });
  });

  group('estimateCalories', () {
    test('70 kg, 5 km için ~362 kcal', () {
      final c = estimateCalories(weightKg: 70, distanceKm: 5);
      expect(c, closeTo(362.6, 0.1));
    });
  });

  group('pacePerKm', () {
    test('25 dk / 5 km → 5:00/km', () {
      final p = pacePerKm(const Duration(minutes: 25), 5000);
      expect(p, const Duration(minutes: 5));
    });

    test('çok kısa mesafede null döner', () {
      expect(pacePerKm(const Duration(seconds: 10), 10), isNull);
    });
  });

  group('formatElapsed', () {
    test('1 saatten az MM:SS', () {
      expect(formatElapsed(const Duration(seconds: 75)), '01:15');
    });

    test('1 saatten fazla H:MM:SS', () {
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('formatPace', () {
    test('5:00 biçimi', () {
      expect(formatPace(const Duration(minutes: 5)), '5:00');
    });
  });
}
