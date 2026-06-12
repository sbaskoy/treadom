import ActivityKit
import SwiftUI
import WidgetKit

// Treadom koşu Live Activity'si: kilit ekranı kartı + Dynamic Island.
//
// Bu dosya `TreadomWidget` (Widget Extension) hedefine aittir. Süre, cihazda
// `Text(_:style:.timer)` ile kendiliğinden ilerler; mesafe/alan/tempo ise
// `Runner` her veri geldiğinde günceller.
@available(iOS 16.1, *)
struct TreadomRunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            // --- Kilit ekranı / banner görünümü ---
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // --- Genişletilmiş (uzun basılı) Dynamic Island ---
                DynamicIslandExpandedRegion(.leading) {
                    StatView(icon: "figure.run", value: context.state.distanceText)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StatView(icon: "square.dashed", value: context.state.areaText)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.startDate, style: .timer)
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 46)
                    .foregroundStyle(.green)
            } minimal: {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
            }
            .keylineTint(.green)
        }
    }
}

// Kilit ekranı kartı.
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RunActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
                Text(context.attributes.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(context.state.startDate, style: .timer)
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            HStack(alignment: .top) {
                StatView(icon: "ruler", value: context.state.distanceText, label: "Mesafe")
                Spacer()
                StatView(icon: "square.dashed", value: context.state.areaText, label: "Alan")
                Spacer()
                StatView(icon: "speedometer", value: context.state.paceText, label: "Tempo")
            }
        }
        .padding()
    }
}

// İkon + değer (+ opsiyonel etiket) gösteren küçük öğe.
@available(iOS 16.1, *)
struct StatView: View {
    let icon: String
    let value: String
    var label: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.green)
            Text(value.isEmpty ? "—" : value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            if let label {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
