import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/foreground_service.dart';
import '../services/live_activity_service.dart';
import '../services/location_service.dart';
import '../services/run_math.dart';

/// Bir koşu/yürüyüş turunun durumu.
enum RunStatus {
  /// Tur başlamadı.
  idle,

  /// Konum aktif olarak takip ediliyor.
  running,

  /// Tur bitti; sonuç (alan/mesafe/süre) gösteriliyor.
  finished,
}

/// Tek bir koşu turunu yöneten sağlayıcı.
///
/// Mobilde (Android/iOS) konum, arka plan izolatındaki foreground service görevi
/// tarafından toplanır ve buraya [FlutterForegroundTask.addTaskDataCallback] ile
/// akar; böylece uygulama arka plandayken bile rota/mesafe büyümeye devam eder.
/// Web'de foreground service olmadığından doğrudan konum akışına abone olunur.
class RunProvider extends ChangeNotifier {
  RunProvider({
    LocationService? service,
    ForegroundService? foregroundService,
    LiveActivityService? liveActivity,
  })  : _service = service ?? LocationService(),
        _foregroundService = foregroundService ?? ForegroundService(),
        _liveActivity = liveActivity ?? LiveActivityService();

  final LocationService _service;
  final ForegroundService _foregroundService;

  /// iOS Live Activity (Dynamic Island) köprüsü; diğer platformlarda no-op.
  final LiveActivityService _liveActivity;

  /// Live Activity metinlerini turun yerelleştirilmiş birimleriyle biçimlemek
  /// için son turun bildirim parametrelerini saklarız.
  RunNotificationParams? _notification;

  StreamSubscription<Position>? _sub; // yalnızca web fallback'inde kullanılır
  Timer? _elapsedTimer;

  RunStatus _status = RunStatus.idle;
  RunStatus get status => _status;
  bool get isRunning => _status == RunStatus.running;

  final List<LatLng> _route = [];

  /// Şimdiye kadar geçilen konum noktaları (rota).
  List<LatLng> get route => List.unmodifiable(_route);

  double _areaM2 = 0;

  /// Rotanın çevrelediği alan (metrekare).
  double get areaM2 => _areaM2;

  double _distanceM = 0;

  /// Toplam katedilen mesafe (metre).
  double get distanceM => _distanceM;

  double _maxSpeedMps = 0;

  /// Tur boyunca gözlenen en yüksek (yumuşatılmış) hız (m/s). Araç hızı / sahte
  /// konum tespiti ve "yürüyerek oyna" kapısı için kullanılır.
  double get maxSpeedMps => _maxSpeedMps;

  // Web fallback'inde hız hesabı için son örnek (mobilde görev izolatı hesaplar).
  DateTime? _lastWebSampleAt;
  double _emaSpeedMps = 0;

  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  /// Tur başından bu yana geçen süre.
  Duration get elapsed => _elapsed;

  /// Ortalama tempo (km başına süre); mesafe çok kısaysa null.
  Duration? get pace => pacePerKm(_elapsed, _distanceM);

  /// Turu başlatır. [notification] arka plan bildirimini kurmak için gereken
  /// yerelleştirilmiş metinleri ve kullanıcı kilosunu taşır.
  Future<void> start({required RunNotificationParams notification}) async {
    _notification = notification;
    _route.clear();
    _areaM2 = 0;
    _distanceM = 0;
    _maxSpeedMps = 0;
    _emaSpeedMps = 0;
    _lastWebSampleAt = null;
    _elapsed = Duration.zero;
    _startedAt = DateTime.now();
    _status = RunStatus.running;
    notifyListeners();

    _startElapsedTimer();

    // iOS Live Activity'yi başlat (Dynamic Island + kilit ekranı). Süre sayacı
    // cihazda kendiliğinden ilerlesin diye başlangıç zamanını veriyoruz.
    await _liveActivity.start(
      title: notification.title,
      startedAtMs: _startedAt!.millisecondsSinceEpoch,
      distanceText: _distanceText(),
      areaText: _areaText(),
      paceText: _paceText(),
    );

    if (_foregroundService.isSupported) {
      await _foregroundService.requestPermissions();
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
      await _foregroundService.start(notification);
    } else {
      // Web: arka plan servisi yok, doğrudan konum akışını dinle.
      _sub = _service.positionStream(distanceFilter: 3).listen(_onWebPosition);
    }
  }

  /// Turu bitirir: takibi durdurur ve sonucu "finished" durumunda dondurur.
  Future<void> stop() async {
    _stopElapsedTimer();
    _freezeElapsed();
    _status = RunStatus.finished;
    await _stopTracking();
    await _liveActivity.end();
    notifyListeners();
  }

  /// Sonucu temizleyip başlangıç durumuna döner (yeni tura hazır).
  Future<void> reset() async {
    _stopElapsedTimer();
    await _stopTracking();
    await _liveActivity.end();
    _route.clear();
    _areaM2 = 0;
    _distanceM = 0;
    _elapsed = Duration.zero;
    _startedAt = null;
    _status = RunStatus.idle;
    notifyListeners();
  }

  // --- İç yardımcılar ---

  /// Arka plan görevinden gelen her yeni konum noktası (mobil yol).
  void _onTaskData(Object data) {
    if (data is! Map) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    _route.add(LatLng(lat, lng));
    // Mesafe/alan/hız otoritesi görevdedir; buradaki değerleri onunla eşitliyoruz.
    _distanceM = (data['distanceM'] as num?)?.toDouble() ?? _distanceM;
    _areaM2 = (data['areaM2'] as num?)?.toDouble() ?? _areaM2;
    _maxSpeedMps = (data['maxSpeedMps'] as num?)?.toDouble() ?? _maxSpeedMps;
    notifyListeners();
    _pushLiveActivity();
  }

  /// Web fallback'inde doğrudan akıştan gelen konum.
  void _onWebPosition(Position pos) {
    final point = LatLng(pos.latitude, pos.longitude);
    final segDist = _route.isNotEmpty ? segmentMeters(_route.last, point) : 0.0;
    if (_route.isNotEmpty) {
      _distanceM += segDist;
    }
    // Hız (araç/sahte konum tespiti) — görev izolatındaki ile aynı mantık.
    var inst = 0.0;
    final last = _lastWebSampleAt;
    if (last != null) {
      final dt = pos.timestamp.difference(last).inMilliseconds / 1000.0;
      if (dt > 0) inst = segDist / dt;
    }
    if (pos.speed.isFinite && pos.speed > inst) inst = pos.speed;
    _lastWebSampleAt = pos.timestamp;
    _emaSpeedMps = _emaSpeedMps == 0 ? inst : 0.5 * _emaSpeedMps + 0.5 * inst;
    if (_emaSpeedMps > _maxSpeedMps) _maxSpeedMps = _emaSpeedMps;

    _route.add(point);
    _areaM2 = planarAreaM2(_route);
    notifyListeners();
    _pushLiveActivity();
  }

  /// Live Activity'yi güncel istatistiklerle tazeler (mesafe/alan değiştikçe).
  /// Süre cihazda kendiliğinden ilerlediğinden saniyelik güncelleme göndermeyiz.
  void _pushLiveActivity() {
    _liveActivity.update(
      distanceText: _distanceText(),
      areaText: _areaText(),
      paceText: _paceText(),
    );
  }

  /// Mesafeyi turun yerelleştirilmiş birimleriyle biçimler (m / km).
  String _distanceText() {
    final n = _notification;
    if (n == null) return '';
    if (_distanceM < 1000) return '${_distanceM.round()} ${n.unitM}';
    return '${(_distanceM / 1000).toStringAsFixed(2)} ${n.unitKm}';
  }

  /// Alanı biçimler (m² / km²).
  String _areaText() {
    if (_areaM2 < 1000000) return '${_areaM2.round()} m²';
    return '${(_areaM2 / 1000000).toStringAsFixed(2)} km²';
  }

  /// Tempoyu biçimler (mesafe çok kısaysa "--").
  String _paceText() {
    final n = _notification;
    if (n == null) return '';
    final p = pace;
    return p != null ? '${formatPace(p)}${n.paceSuffix}' : '--${n.paceSuffix}';
  }

  Future<void> _stopTracking() async {
    if (_foregroundService.isSupported) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      await _foregroundService.stop();
    } else {
      await _sub?.cancel();
      _sub = null;
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _freezeElapsed();
      notifyListeners();
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _freezeElapsed() {
    final started = _startedAt;
    if (started != null) {
      _elapsed = DateTime.now().difference(started);
    }
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    _sub?.cancel();
    _liveActivity.end();
    if (_foregroundService.isSupported) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    }
    super.dispose();
  }
}
