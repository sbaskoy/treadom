import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'run_math.dart';

/// [FlutterForegroundTask.saveData] ile saklanıp görev izolatında okunan koşu
/// parametrelerinin anahtarı (JSON string).
const String kRunParamsKey = 'run.params';

/// Foreground service başlatılırken çağrılan giriş noktası. Arka plan izolatında
/// çalışır; bu yüzden `vm:entry-point` ile işaretlenmelidir.
@pragma('vm:entry-point')
void startRunCallback() {
  FlutterForegroundTask.setTaskHandler(RunTaskHandler());
}

/// Arka plan izolatında koşuyu yürüten görev.
///
/// Konumu doğrudan burada dinler (ana izolat arka planda donabileceği için),
/// mesafe/alan/tempo/kaloriyi hesaplar, her saniye bildirimi günceller ve her
/// yeni noktayı ana izolata gönderir (harita çizimi için).
class RunTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _sub;

  final List<LatLng> _route = [];
  double _distanceM = 0;
  double _areaM2 = 0;
  DateTime _startedAt = DateTime.now();

  // Hız takibi (araç hızı / sahte konum tespiti için). GPS gürültüsüne karşı
  // anlık hız üstel hareketli ortalamayla (EMA) yumuşatılır; turun en yüksek
  // yumuşatılmış hızı saklanır.
  double _maxSpeedMps = 0;
  double _emaSpeedMps = 0;
  DateTime? _lastSampleAt;

  // Ana izolattan gelen yerelleştirilmiş metin parçaları ve kullanıcı kilosu.
  String _title = 'Treadom';
  String _unitKm = 'km';
  String _unitM = 'm';
  String _unitKcal = 'kcal';
  String _paceSuffix = '/km';
  double _weightKg = 70;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startedAt = timestamp;
    await _loadParams();
    _sub = Geolocator.getPositionStream(locationSettings: _locationSettings())
        .listen(_onPosition);
  }

  Future<void> _loadParams() async {
    final raw = await FlutterForegroundTask.getData<String>(key: kRunParamsKey);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _title = m['title'] as String? ?? _title;
      _unitKm = m['unitKm'] as String? ?? _unitKm;
      _unitM = m['unitM'] as String? ?? _unitM;
      _unitKcal = m['unitKcal'] as String? ?? _unitKcal;
      _paceSuffix = m['paceSuffix'] as String? ?? _paceSuffix;
      _weightKg = (m['weightKg'] as num?)?.toDouble() ?? _weightKg;
    } catch (_) {
      // Bozuk veri olursa varsayılanlarla devam et.
    }
  }

  LocationSettings _locationSettings() {
    const accuracy = LocationAccuracy.high;
    const filter = 3;
    if (Platform.isAndroid) {
      return AndroidSettings(accuracy: accuracy, distanceFilter: filter);
    }
    if (Platform.isIOS) {
      // iOS'ta arka planda konum alabilmek için bu ayarlar şarttır.
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: filter,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: accuracy, distanceFilter: filter);
  }

  void _onPosition(Position pos) {
    final point = LatLng(pos.latitude, pos.longitude);
    final segDist = _route.isNotEmpty ? segmentMeters(_route.last, point) : 0.0;
    if (_route.isNotEmpty) {
      _distanceM += segDist;
    }
    _updateSpeed(pos, segDist);
    _route.add(point);
    _areaM2 = planarAreaM2(_route);

    // Her noktayı ana izolata gönder; RunProvider rotayı/çizimi günceller.
    FlutterForegroundTask.sendDataToMain({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'distanceM': _distanceM,
      'areaM2': _areaM2,
      'maxSpeedMps': _maxSpeedMps,
    });
  }

  /// Anlık hızı (GPS Doppler hızı ile konumdan türetilen hızın büyüğü) hesaplar,
  /// EMA ile yumuşatır ve turun en yüksek yumuşatılmış hızını günceller.
  void _updateSpeed(Position pos, double segDist) {
    var inst = 0.0;
    final last = _lastSampleAt;
    if (last != null) {
      final dt = pos.timestamp.difference(last).inMilliseconds / 1000.0;
      if (dt > 0) inst = segDist / dt;
    }
    // GPS'in bildirdiği hız (varsa) genelde daha güvenilirdir; büyüğünü al.
    if (pos.speed.isFinite && pos.speed > inst) inst = pos.speed;
    _lastSampleAt = pos.timestamp;

    _emaSpeedMps = _emaSpeedMps == 0 ? inst : 0.5 * _emaSpeedMps + 0.5 * inst;
    if (_emaSpeedMps > _maxSpeedMps) _maxSpeedMps = _emaSpeedMps;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final elapsed = timestamp.difference(_startedAt);
    FlutterForegroundTask.updateService(
      notificationTitle: _title,
      notificationText: _notificationText(elapsed),
    );
  }

  String _notificationText(Duration elapsed) {
    final pace = pacePerKm(elapsed, _distanceM);
    final paceStr =
        pace != null ? '${formatPace(pace)}$_paceSuffix' : '--$_paceSuffix';
    final cal = estimateCalories(
      weightKg: _weightKg,
      distanceKm: _distanceM / 1000,
    ).round();
    return '${formatElapsed(elapsed)} · ${_formatDistance(_distanceM)} · '
        '$paceStr · $cal $_unitKcal';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} $_unitM';
    return '${(meters / 1000).toStringAsFixed(2)} $_unitKm';
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
    _sub = null;
  }
}
