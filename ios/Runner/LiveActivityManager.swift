import ActivityKit
import Flutter
import Foundation

// Flutter ↔ ActivityKit köprüsü. `treadom/live_activity` MethodChannel'ını
// dinler; koşu başlayınca Live Activity başlatır, veri geldikçe günceller,
// tur bitince kapatır.
//
// Bu dosya `Runner` hedefine eklenmelidir (Xcode'da Target Membership: Runner).
class LiveActivityManager {
    static let shared = LiveActivityManager()

    func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "treadom/live_activity",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "start": self.start(args, result: result)
            case "update": self.update(args, result: result)
            case "end": self.end(result: result)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }

    private func start(_ args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(nil) // Kullanıcı Live Activity'leri kapatmış.
            return
        }
        endAllActivities() // Önceki aktiviteyi temizle.

        let title = args["title"] as? String ?? "Treadom"
        let state = RunActivityAttributes.ContentState(
            startedAtMs: (args["startedAtMs"] as? NSNumber)?.doubleValue
                ?? Date().timeIntervalSince1970 * 1000,
            distanceText: args["distanceText"] as? String ?? "",
            areaText: args["areaText"] as? String ?? "",
            paceText: args["paceText"] as? String ?? ""
        )
        do {
            let activity = try Activity.request(
                attributes: RunActivityAttributes(title: title),
                contentState: state,
                pushType: nil
            )
            result(activity.id)
        } catch {
            result(FlutterError(
                code: "live_activity_start_failed",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func update(_ args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else { result(nil); return }
        Task {
            for activity in Activity<RunActivityAttributes>.activities {
                let prev = activity.contentState
                let next = RunActivityAttributes.ContentState(
                    startedAtMs: prev.startedAtMs, // başlangıç anı sabit kalır
                    distanceText: args["distanceText"] as? String ?? prev.distanceText,
                    areaText: args["areaText"] as? String ?? prev.areaText,
                    paceText: args["paceText"] as? String ?? prev.paceText
                )
                await activity.update(using: next)
            }
            result(nil)
        }
    }

    private func end(result: @escaping FlutterResult) {
        endAllActivities()
        result(nil)
    }

    private func endAllActivities() {
        guard #available(iOS 16.1, *) else { return }
        Task {
            for activity in Activity<RunActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
