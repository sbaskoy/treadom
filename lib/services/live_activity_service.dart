import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS Live Activity (Dynamic Island + kilit ekranı canlı widget) köprüsü.
///
/// Koşu sürerken kilit ekranında ve Dynamic Island'da süre/mesafe/alan/tempo
/// gösterir. Native taraf (ActivityKit) yalnızca iOS 16.1+ üzerinde çalışır;
/// diğer platformlarda (Android/web) tüm çağrılar sessizce yok sayılır (no-op).
///
/// Native uç: `ios/Runner/LiveActivityManager.swift` (MethodChannel
/// `treadom/live_activity`). Görsel: `ios/TreadomWidget/...` (SwiftUI).
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('treadom/live_activity');

  /// Live Activity yalnızca iOS'ta anlamlıdır. `defaultTargetPlatform`
  /// kullanıyoruz ki `dart:io` import etmeden web'de de güvenli olsun.
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool _active = false;

  /// Şu an aktif bir Live Activity var mı?
  bool get isActive => _active;

  /// Koşu başlarken Live Activity'yi başlatır.
  ///
  /// [startedAtMs] cihazda kendi kendine ilerleyen süre sayacı için kullanılır
  /// (her saniye güncelleme göndermeye gerek kalmaz). Diğer alanlar önceden
  /// biçimlenmiş metinlerdir (biçimleme/yerelleştirme Dart tarafında kalır).
  Future<void> start({
    required String title,
    required int startedAtMs,
    required String distanceText,
    required String areaText,
    required String paceText,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('start', {
        'title': title,
        'startedAtMs': startedAtMs,
        'distanceText': distanceText,
        'areaText': areaText,
        'paceText': paceText,
      });
      _active = true;
    } on PlatformException {
      // Live Activity sistemden kapalıysa / izin yoksa sessizce geç.
      _active = false;
    } on MissingPluginException {
      _active = false;
    }
  }

  /// Canlı istatistikleri günceller (mesafe/alan değiştikçe çağrılır).
  Future<void> update({
    required String distanceText,
    required String areaText,
    required String paceText,
  }) async {
    if (!_supported || !_active) return;
    try {
      await _channel.invokeMethod('update', {
        'distanceText': distanceText,
        'areaText': areaText,
        'paceText': paceText,
      });
    } on PlatformException {
      // yok say
    } on MissingPluginException {
      // yok say
    }
  }

  /// Tur bitince Live Activity'yi kapatır.
  Future<void> end() async {
    if (!_supported || !_active) return;
    _active = false;
    try {
      await _channel.invokeMethod('end');
    } on PlatformException {
      // yok say
    } on MissingPluginException {
      // yok say
    }
  }
}
