import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // iOS Live Activity (Dynamic Island) köprüsünü kaydet.
    if let controller = window?.rootViewController as? FlutterViewController {
      LiveActivityManager.shared.register(messenger: controller.binaryMessenger)
    }

    // flutter_foreground_task: arka plan görev izolatında eklentilerin
    // (geolocator vb.) kayıtlı olması için gereklidir.
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
