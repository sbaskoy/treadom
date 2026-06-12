import 'package:geolocator/geolocator.dart';

/// Cihaz konumuna erişimi (izinler, anlık konum ve canlı konum akışı)
/// tek bir yerde toplayan servis.
///
/// UI ve sağlayıcı katmanı doğrudan `geolocator` API'siyle değil bu servisle
/// konuşur; böylece izin mantığı tek noktada kalır ve test edilebilir olur.
class LocationService {
  /// Cihazda konum servisinin (GPS) açık olup olmadığını döner.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Mevcut izin durumunu sorgular.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Kullanıcıdan konum izni ister ve sonuç durumunu döner.
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// Uygulamanın sistem ayarları sayfasını açar (izin "kalıcı olarak reddedildi"
  /// durumunda kullanıcı izni elle açabilsin diye).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Cihazın konum ayarları sayfasını açar (GPS kapalıyken açtırmak için).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Anlık (tek seferlik) konumu yüksek doğrulukla getirir.
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Kullanıcı hareket ettikçe yeni konum yayınlayan canlı akış.
  ///
  /// [distanceFilter] metre cinsinden: konum yalnızca kullanıcı bu kadar yer
  /// değiştirdiğinde güncellenir (pil tasarrufu ve gürültü azaltma).
  Stream<Position> positionStream({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
