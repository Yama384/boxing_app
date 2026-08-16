//
//  TimerLiveActivity.swift
//  Referenz-Datei -- NICHT Teil des Xcode-Projekts.
//
//  So einbinden:
//  1. In Xcode (ios/Runner.xcworkspace): File > New > Target... > Widget
//     Extension. Produktname z.B. "TimerWidget", "Include Live Activity"
//     anhaken, "Embed in Application: Runner".
//  2. Xcode legt dabei automatisch eine Datei mit ähnlichem Namen an
//     (z.B. TimerWidgetLiveActivity.swift) -- deren Inhalt komplett durch
//     den Inhalt dieser Datei ersetzen.
//  3. Die Konstante `appGroupId` unten muss exakt mit
//     `_liveActivityAppGroupId` in lib/services/background_timer_controller.dart
//     übereinstimmen.
//  4. Ausführliche Schritt-für-Schritt-Anleitung: siehe
//     ios/LIVE_ACTIVITY_SETUP.md im gleichen Ordner wie diese Datei.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Name MUSS exakt "LiveActivitiesAppAttributes" heißen -- Vorgabe des
// live_activities-Flutter-Pakets. Bei abweichendem Namen wird die Live
// Activity zwar erstellt, aber nie angezeigt.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {}

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

// WICHTIG: exakt dieselbe App-Group-ID wie in
// lib/services/background_timer_controller.dart (_liveActivityAppGroupId)
// und im Xcode-Capabilities-Tab von Runner UND dieser Extension.
private let appGroupId = "group.com.example.boxingApp.timer"
private let sharedDefaults = UserDefaults(suiteName: appGroupId)!

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let label = sharedDefaults.string(forKey: context.attributes.prefixedKey("label")) ?? "Timer"
            let endTimeMillis = sharedDefaults.double(forKey: context.attributes.prefixedKey("endTimeMillis"))
            let endDate = Date(timeIntervalSince1970: endTimeMillis / 1000)

            // Sperrbildschirm-Ansicht
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                if endDate > Date() {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                } else {
                    Text("00:00")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            let label = sharedDefaults.string(forKey: context.attributes.prefixedKey("label")) ?? "Timer"
            let endTimeMillis = sharedDefaults.double(forKey: context.attributes.prefixedKey("endTimeMillis"))
            let endDate = Date(timeIntervalSince1970: endTimeMillis / 1000)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(label).font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if endDate > Date() {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .monospacedDigit()
                    } else {
                        Text("00:00").monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                if endDate > Date() {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 40)
                } else {
                    Text("00:00").monospacedDigit().frame(width: 40)
                }
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
