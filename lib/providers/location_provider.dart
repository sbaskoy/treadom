import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

/// Konum akışının kullanıcı arayüzüne yansıyan durumu.
enum LocationStatus {
  /// Henüz izin/servis kontrolü yapılmadı (ilk açılış).
  initial,

  /// İzin/konum bekleniyor.
  loading,

  /// Geçerli bir konum var ve akış çalışıyor.
  ready,

  /// Cihazın konum servisi (GPS) kapalı.
  serviceDisabled,

  /// Kullanıcı izni reddetti (tekrar istenebilir).
  permissionDenied,

  /// İzin kalıcı olarak reddedildi; yalnızca sistem ayarlarından açılabilir.
  permissionDeniedForever,
}

/// Kullanıcının canlı konumunu yöneten sağlayıcı.
///
/// İzinleri ister, konum akışını başlatır ve son konumu dinleyicilere yayar.
/// Harita ekranı bu sağlayıcıyı izleyerek kendini günceller.
class LocationProvider extends ChangeNotifier {
  LocationProvider({LocationService? service})
      : _service = service ?? LocationService();

  final LocationService _service;
  StreamSubscription<Position>? _positionSub;

  LocationStatus _status = LocationStatus.initial;
  LocationStatus get status => _status;

  Position? _position;

  /// Bilinen son konum (henüz alınmadıysa null).
  Position? get position => _position;

  /// İzin ve konum servisini kontrol edip akışı başlatır.
  ///
  /// İzin yoksa kullanıcıdan ister. Sonuca göre [status] güncellenir.
  /// Harita ekranı açıldığında ve "tekrar dene" aksiyonunda çağrılır.
  Future<void> initLocation() async {
    _setStatus(LocationStatus.loading);

    // 1) Konum servisi (GPS) açık mı?
    if (!await _service.isServiceEnabled()) {
      _setStatus(LocationStatus.serviceDisabled);
      return;
    }

    // 2) İzin durumunu kontrol et, gerekiyorsa iste.
    var permission = await _service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _service.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _setStatus(LocationStatus.permissionDeniedForever);
      return;
    }
    if (permission == LocationPermission.denied) {
      _setStatus(LocationStatus.permissionDenied);
      return;
    }

    // 3) İzin var: önce hızlıca anlık konumu al, sonra canlı akışa geç.
    try {
      _position = await _service.getCurrentPosition();
      _setStatus(LocationStatus.ready);
    } catch (_) {
      // Anlık konum alınamasa bile akış birazdan konum getirebilir;
      // bu yüzden burada hata durumuna düşmeyip akışı bekliyoruz.
    }

    _startStream();
  }

  /// Canlı konum akışına abone olur (varsa önce eskisini kapatır).
  void _startStream() {
    _positionSub?.cancel();
    _positionSub = _service.positionStream().listen(
      (pos) {
        _position = pos;
        _status = LocationStatus.ready;
        // Konum her güncellendiğinde haritanın yenilenmesi için durum aynı
        // kalsa bile dinleyicileri uyarıyoruz.
        notifyListeners();
      },
      onError: (_) {
        // Akış hata verirse (örn. servis kapatıldı) durumu güncelle.
        _setStatus(LocationStatus.serviceDisabled);
      },
    );
  }

  /// Sistem ayarlarını açar (kalıcı ret durumunda kullanıcı izni açabilsin).
  Future<void> openAppSettings() => _service.openAppSettings();

  /// Cihazın konum ayarlarını açar (GPS kapalıyken).
  Future<void> openLocationSettings() => _service.openLocationSettings();

  void _setStatus(LocationStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
