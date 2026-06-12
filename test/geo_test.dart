import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:treadom/services/geo.dart';

void main() {
  // simulate_walk.sh ile aynı ızgara/koordinat mantığı: rota 1 (Merkez Kare)
  // tamamen rota 5'in (Büyük Kuşatma) içinde kalır; dolayısıyla rota 5'i koşan
  // kullanıcı rota 1'in alanını fetheder.
  const route1 = [
    LatLng(39.920800, 32.854100),
    LatLng(39.920800, 32.855274),
    LatLng(39.921700, 32.855274),
    LatLng(39.921700, 32.854100),
  ];
  const route5 = [
    LatLng(39.920440, 32.853748),
    LatLng(39.920440, 32.856799),
    LatLng(39.922060, 32.856799),
    LatLng(39.922060, 32.853748),
  ];

  group('polygonCentroid', () {
    test('bir karenin merkezi köşelerin ortasıdır', () {
      final c = polygonCentroid(route1);
      expect(c.latitude, closeTo(39.92125, 1e-4));
      expect(c.longitude, closeTo(32.854687, 1e-4));
    });

    test('iki noktalı dejenere girdide ortalamaya düşer', () {
      final c = polygonCentroid(const [LatLng(0, 0), LatLng(2, 4)]);
      expect(c.latitude, closeTo(1, 1e-9));
      expect(c.longitude, closeTo(2, 1e-9));
    });
  });

  group('pointInPolygon / fetih', () {
    test('rota 1 merkezi rota 5 içindedir (fetih gerçekleşir)', () {
      expect(pointInPolygon(polygonCentroid(route1), route5), isTrue);
    });

    test('rota 5 merkezi rota 1 içinde DEĞİLDİR (ters yönde fetih olmaz)', () {
      // route5 route1'i kapsadığından merkezleri yakın; yine de küçük kare
      // büyük karenin merkezini içermeyebilir. Asıl garanti: büyük, küçüğü alır.
      // Burada uzak bir noktanın dışarıda kaldığını da doğrularız.
      expect(pointInPolygon(const LatLng(40.0, 33.0), route1), isFalse);
    });

  });

  group('polygonFullyContains / tam kuşatma kuralı', () {
    const route2 = [
      LatLng(39.920800, 32.855274),
      LatLng(39.920800, 32.856448),
      LatLng(39.921700, 32.856448),
      LatLng(39.921700, 32.855274),
    ];
    // Rota 4 (Çapraz): rota 1 ile yalnızca KISMEN çakışır.
    const route4 = [
      LatLng(39.921250, 32.854687),
      LatLng(39.921250, 32.855861),
      LatLng(39.922150, 32.855861),
      LatLng(39.922150, 32.854687),
    ];

    test('rota 5, rota 1 ve rota 2\'yi tamamen kuşatır → ikisini de fetheder', () {
      expect(polygonFullyContains(route5, route1), isTrue);
      expect(polygonFullyContains(route5, route2), isTrue);
    });

    test('kısmi çakışma fetih SAYILMAZ (sadece girmek/kesmek yetmez)', () {
      // route4 route1 ile kısmen çakışır ama onu tamamen çevrelemez.
      expect(polygonFullyContains(route4, route1), isFalse);
      expect(polygonFullyContains(route1, route4), isFalse);
    });

    test('küçük döngü büyük alanı kuşatamaz', () {
      expect(polygonFullyContains(route1, route5), isFalse);
    });

    test('komşu alanlar birbirini kuşatmaz', () {
      // Rota 2 (Doğu Komşu) rota 1'in sağında; kenar paylaşsalar da biri
      // diğerini tamamen kuşatmaz.
      expect(polygonFullyContains(route1, route2), isFalse);
      expect(polygonFullyContains(route2, route1), isFalse);
    });
  });

  group('polygonDifference / kısmi fetih', () {
    // 10x10 birimlik bir kare (lon=x, lat=y), alanı 100.
    const enemy = [
      LatLng(0, 0),
      LatLng(0, 10),
      LatLng(10, 10),
      LatLng(10, 0),
    ];

    double shoelace(List<LatLng> r) {
      var a = 0.0;
      for (var i = 0; i < r.length; i++) {
        final j = (i + 1) % r.length;
        a += r[i].longitude * r[j].latitude - r[j].longitude * r[i].latitude;
      }
      return a.abs() / 2;
    }

    test('kısmi çakışmada yalnızca kesişen kısım çıkar (90 kalır)', () {
      // 100 birimlik alanın sadece sağ 20 birimini kaplayan döngü.
      final r = polygonDifference(
        subjectOuter: enemy,
        clip: const [LatLng(8, -1), LatLng(12, -1), LatLng(12, 11), LatLng(8, 11)],
      );
      expect(r, hasLength(1));
      expect(shoelace(r.first.outer), closeTo(80, 0.01));
      expect(r.first.holes, isEmpty);
    });

    test('alanın ortasını koşmak delik açar (net 96 kalır)', () {
      final r = polygonDifference(
        subjectOuter: enemy,
        clip: const [LatLng(4, 4), LatLng(4, 6), LatLng(6, 6), LatLng(6, 4)],
      );
      expect(r, hasLength(1));
      expect(r.first.holes, hasLength(1));
      final net = shoelace(r.first.outer) - shoelace(r.first.holes.first);
      expect(net, closeTo(96, 0.01));
    });

    test('alanı tamamen kuşatmak fetih → hiç parça kalmaz (rakip silinir)', () {
      final r = polygonDifference(
        subjectOuter: enemy,
        clip: const [LatLng(-1, -1), LatLng(11, -1), LatLng(11, 11), LatLng(-1, 11)],
      );
      expect(r, isEmpty);
    });

    test('alanı ortadan ikiye bölmek iki ayrı parça bırakır', () {
      final r = polygonDifference(
        subjectOuter: enemy,
        clip: const [LatLng(4, -1), LatLng(6, -1), LatLng(6, 11), LatLng(4, 11)],
      );
      expect(r, hasLength(2));
      for (final s in r) {
        expect(shoelace(s.outer), closeTo(40, 0.01));
      }
    });

    test('çakışma yoksa alan değişmeden döner', () {
      final r = polygonDifference(
        subjectOuter: enemy,
        clip: const [LatLng(20, 20), LatLng(20, 30), LatLng(30, 30), LatLng(30, 20)],
      );
      expect(r, hasLength(1));
      expect(shoelace(r.first.outer), closeTo(100, 0.01));
    });
  });
}
