// validateRunLoop (halka kapatma mekaniği) birim testleri.
//
// Kurallar:
// - Koşu yeterince uzamadıysa alan oluşmaz (tooShort).
// - Alanı yokken halka, başlangıca geri dönünce kapanır.
// - Kendi alanından başlayan koşu, ancak kendi alanına dönerse kapanır;
//   dışarıda kendi alanına dönmeden atılan tur fetih SAYILMAZ.
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:treadom/services/geo.dart';

void main() {
  // ~100 m × 100 m kare bir alan (köşesi orijinde).
  final ownSquare = TerritoryShape(
    outer: const [
      LatLng(0, 0),
      LatLng(0, 0.0009),
      LatLng(0.0009, 0.0009),
      LatLng(0.0009, 0),
    ],
  );
  const ownCenter = LatLng(0.00045, 0.00045);

  group('validateRunLoop — alan yokken (başlangıç çapası)', () {
    test('başlangıca dönen kapalı kare halka geçerli', () {
      final r = validateRunLoop(
        route: const [
          LatLng(0, 0),
          LatLng(0, 0.0009),
          LatLng(0.0009, 0.0009),
          LatLng(0.0009, 0),
          LatLng(0, 0),
        ],
        ownShapes: const [],
      );
      expect(r.valid, isTrue);
      expect(r.polygon.length, greaterThanOrEqualTo(3));
    });

    test('başlangıca dönmeyen açık iz geçersiz (notClosed)', () {
      final r = validateRunLoop(
        route: const [
          LatLng(0, 0),
          LatLng(0, 0.0009),
          LatLng(0.0009, 0.0009),
          LatLng(0.0018, 0.0018),
        ],
        ownShapes: const [],
      );
      expect(r.valid, isFalse);
      expect(r.reason, LoopFailReason.notClosed);
    });

    test('başlangıca dönse de alan çevrelemeyen ince iz geçersiz', () {
      // Aynı çizgide ~120 m gidip neredeyse aynı çizgiden geri dönmek: son nokta
      // başlangıca yakın (kapanmış görünür) ama çevrelenen alan ~0 m².
      final r = validateRunLoop(
        route: const [
          LatLng(0, 0),
          LatLng(0, 0.0006),
          LatLng(0, 0.0011),
          LatLng(0, 0.0006),
          LatLng(0, 0.00001), // başlangıca ~1 m
        ],
        ownShapes: const [],
      );
      expect(r.valid, isFalse);
      expect(r.reason, LoopFailReason.notClosed);
    });

    test('çok kısa tur geçersiz (tooShort)', () {
      final r = validateRunLoop(
        route: const [
          LatLng(0, 0),
          LatLng(0, 0.0001),
          LatLng(0.0001, 0.0001),
          LatLng(0, 0),
        ],
        ownShapes: const [],
      );
      expect(r.valid, isFalse);
      expect(r.reason, LoopFailReason.tooShort);
    });
  });

  group('validateRunLoop — kendi alanından başlayınca', () {
    test('dışarı çıkıp kendi alanına dönen tur geçerli', () {
      final r = validateRunLoop(
        route: const [
          ownCenter,
          LatLng(0.00045, 0.005), // ~500 m doğuya (dışarı)
          LatLng(0.0010, 0.005),
          ownCenter, // kendi alanına dönüş
        ],
        ownShapes: [ownSquare],
      );
      expect(r.valid, isTrue);
    });

    test('dışarıda kendi alanına dönmeden atılan tur geçersiz (point 4)', () {
      final r = validateRunLoop(
        route: const [
          ownCenter, // kendi alanından başla
          LatLng(0.00045, 0.005),
          LatLng(0.0010, 0.005),
          LatLng(0.0010, 0.0055),
          LatLng(0.00045, 0.005), // uzakta kapanır ama kendi alanı DEĞİL
        ],
        ownShapes: [ownSquare],
      );
      expect(r.valid, isFalse);
      expect(r.reason, LoopFailReason.notClosed);
    });
  });

  group('validateRunLoop — alanı olsa da uzakta başlayınca', () {
    test('başka yerde başlangıca dönen halka yeni (ayrık) alan açar', () {
      final r = validateRunLoop(
        route: const [
          LatLng(0, 0.01), // kendi alanından ~1 km uzak
          LatLng(0, 0.0109),
          LatLng(0.0009, 0.0109),
          LatLng(0.0009, 0.01),
          LatLng(0, 0.01),
        ],
        ownShapes: [ownSquare],
      );
      expect(r.valid, isTrue);
    });
  });
}
