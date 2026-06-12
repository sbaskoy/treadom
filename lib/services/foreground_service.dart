import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'run_task_handler.dart';

/// Koşu bildirimini kurmak için ana izolattan görev izolatına aktarılan
/// (yerelleştirilmiş) parametreler.
class RunNotificationParams {
  const RunNotificationParams({
    required this.title,
    required this.initialText,
    required this.channelName,
    required this.unitKm,
    required this.unitM,
    required this.unitKcal,
    required this.paceSuffix,
    required this.weightKg,
  });

  final String title;
  final String initialText;
  final String channelName;
  final String unitKm;
  final String unitM;
  final String unitKcal;
  final String paceSuffix;
  final double weightKg;

  /// Görev izolatının okuyacağı JSON gövdesi (kanal adı ve ilk metin hariç;
  /// onlar doğrudan startService'e verilir).
  Map<String, dynamic> toHandlerJson() => {
        'title': title,
        'unitKm': unitKm,
        'unitM': unitM,
        'unitKcal': unitKcal,
        'paceSuffix': paceSuffix,
        'weightKg': weightKg,
      };
}

/// `flutter_foreground_task` için ince bir sarmalayıcı.
///
/// Foreground service'in (arka plan koşu takibi + canlı bildirim) yaşam
/// döngüsünü tek bir yerde toplar. Web'de tüm çağrılar no-op'tur.
class ForegroundService {
  bool _initialized = false;

  /// Foreground service yalnızca Android/iOS'ta desteklenir. RunProvider buna
  /// göre mobilde arka plan yolunu, web'de doğrudan akış yolunu seçer.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _supported => isSupported;

  void _ensureInit(String channelName) {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'treadom_run',
        channelName: channelName,
        // Sessiz, düşük öncelikli kalıcı bildirim (koşu boyunca durur).
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Bildirimi saniyede bir güncellemek için onRepeatEvent'i tetikler.
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// Bildirim iznini (Android 13+) kontrol eder, gerekiyorsa ister.
  Future<bool> requestPermissions() async {
    if (!_supported) return true;
    final current = await FlutterForegroundTask.checkNotificationPermission();
    if (current == NotificationPermission.granted) return true;
    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Koşu foreground service'ini başlatır ve canlı bildirimi gösterir.
  Future<void> start(RunNotificationParams params) async {
    if (!_supported) return;
    _ensureInit(params.channelName);

    // Görev izolatının okuyacağı parametreleri sakla.
    await FlutterForegroundTask.saveData(
      key: kRunParamsKey,
      value: jsonEncode(params.toHandlerJson()),
    );

    await FlutterForegroundTask.startService(
      serviceId: 200,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: params.title,
      notificationText: params.initialText,
      callback: startRunCallback,
    );
  }

  /// Servisi durdurur (bildirim kalkar).
  Future<void> stop() async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
