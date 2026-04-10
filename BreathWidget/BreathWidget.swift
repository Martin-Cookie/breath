import WidgetKit
import SwiftUI
import Charts

// MARK: - Entry

struct BreathEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Provider

struct BreathTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BreathEntry {
        BreathEntry(
            date: .now,
            snapshot: WidgetSnapshot(
                currentStreak: 5,
                bestStreak: 12,
                lastSessionDate: .now,
                recentRetentions: [60, 75, 90, 85, 100, 95, 110]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BreathEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreathEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupIdentifier)
        let snapshot: WidgetSnapshot = {
            guard let data = defaults?.data(forKey: WidgetSnapshot.snapshotKey),
                  let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
            else {
                return .empty
            }
            return decoded
        }()

        let entry = BreathEntry(date: .now, snapshot: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Views

private let primaryTeal = Color(red: 0x0d / 255, green: 0x4f / 255, blue: 0x52 / 255)

struct BreathWidgetSmallView: View {
    let entry: BreathEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 28))
            Text("\(entry.snapshot.currentStreak)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTeal)
            Text("dní v řadě")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            primaryTeal.opacity(0.08)
        }
    }
}

struct BreathWidgetMediumView: View {
    let entry: BreathEntry

    private var chartData: [(index: Int, retention: Double)] {
        entry.snapshot.recentRetentions.enumerated().map { ($0.offset, $0.element) }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(entry.snapshot.currentStreak)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryTeal)
                }
                Text("dní v řadě")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Nejdelší: \(entry.snapshot.bestStreak)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            chartSection
                .frame(maxWidth: .infinity)
        }
        .padding(4)
        .containerBackground(for: .widget) {
            primaryTeal.opacity(0.08)
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        if entry.snapshot.recentRetentions.allSatisfy({ $0 == 0 }) {
            VStack {
                Text("Retention")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("7 dní")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Chart(chartData, id: \.index) { point in
                    LineMark(
                        x: .value("Day", point.index),
                        y: .value("Retention", point.retention)
                    )
                    .foregroundStyle(primaryTeal)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Day", point.index),
                        y: .value("Retention", point.retention)
                    )
                    .foregroundStyle(primaryTeal.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
    }
}

struct BreathWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BreathEntry

    var body: some View {
        switch family {
        case .systemMedium:
            BreathWidgetMediumView(entry: entry)
        default:
            BreathWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget

struct BreathWidget: Widget {
    let kind: String = "BreathWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreathTimelineProvider()) { entry in
            BreathWidgetView(entry: entry)
        }
        .configurationDisplayName("Breath")
        .description("Sleduj svůj streak a retention.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct BreathWidgetBundle: WidgetBundle {
    var body: some Widget {
        BreathWidget()
    }
}
