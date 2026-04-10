import WidgetKit
import SwiftUI

struct BreathWidget: Widget {
    let kind: String = "BreathWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreathTimelineProvider()) { entry in
            BreathWidgetView(entry: entry)
        }
        .configurationDisplayName("Breath")
        .description("Sleduj svůj streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BreathEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let lastSession: Date?
}

struct BreathTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BreathEntry {
        BreathEntry(date: .now, streak: 5, lastSession: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (BreathEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreathEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.cz.martinkoci.breath")
        let streak = defaults?.integer(forKey: "stats.currentStreak") ?? 0
        let lastInterval = defaults?.double(forKey: "stats.lastSessionDate") ?? 0
        let lastSession: Date? = lastInterval > 0 ? Date(timeIntervalSince1970: lastInterval) : nil
        let entry = BreathEntry(date: .now, streak: streak, lastSession: lastSession)
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct BreathWidgetView: View {
    let entry: BreathEntry

    var body: some View {
        VStack(spacing: 8) {
            Text("🔥 \(entry.streak)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("dní v řadě")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(red: 0x0d / 255, green: 0x4f / 255, blue: 0x52 / 255).opacity(0.1)
        }
    }
}

@main
struct BreathWidgetBundle: WidgetBundle {
    var body: some Widget {
        BreathWidget()
    }
}
