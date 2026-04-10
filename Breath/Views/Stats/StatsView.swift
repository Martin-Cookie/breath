import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: StoreService
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var period: Period = .week
    @State private var showPaywall = false

    enum Period: String, CaseIterable, Identifiable {
        case week
        case month
        case all
        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return nil
            }
        }

        var localizedTitle: String {
            switch self {
            case .week: return String(localized: "stats.period.week")
            case .month: return String(localized: "stats.period.month")
            case .all: return String(localized: "stats.period.all")
            }
        }

        var isPremium: Bool {
            self != .week
        }
    }

    /// Free tier vidí maximálně `Constants.Freemium.freeHistoryDays` dnů historie.
    private var accessibleSessions: [Session] {
        if store.isPremium { return sessions }
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -Constants.Freemium.freeHistoryDays,
            to: .now
        ) ?? .now
        return sessions.filter { $0.date >= cutoff }
    }

    private var filteredSessions: [Session] {
        let base = accessibleSessions
        guard let days = period.days else { return base }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return base.filter { $0.date >= cutoff }
    }

    private var streak: StreakService.StreakInfo {
        StreakService.compute(from: sessions)
    }

    private var totalTime: TimeInterval {
        sessions.map(\.totalDuration).reduce(0, +)
    }

    private var bestRetentionEver: TimeInterval {
        sessions.map(\.bestRetention).max() ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statCardsRow1
                statCardsRow2

                Text(String(localized: "stats.retention_chart"))
                    .font(.headline)
                    .foregroundStyle(Constants.Palette.primaryTeal)

                chart

                Picker("", selection: Binding(
                    get: { period },
                    set: { newValue in
                        if newValue.isPremium && !store.isPremium {
                            showPaywall = true
                        } else {
                            period = newValue
                        }
                    }
                )) {
                    ForEach(Period.allCases) { p in
                        HStack {
                            Text(p.localizedTitle)
                            if p.isPremium && !store.isPremium {
                                Image(systemName: "lock.fill")
                            }
                        }
                        .tag(p)
                    }
                }
                .pickerStyle(.segmented)

                Text(String(localized: "stats.history"))
                    .font(.headline)
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .padding(.top, 8)

                if filteredSessions.isEmpty {
                    emptyHistory
                } else {
                    ForEach(filteredSessions) { session in
                        SessionRowView(session: session)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "stats.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var statCardsRow1: some View {
        HStack(spacing: 12) {
            statCard(value: "\(sessions.count)", label: String(localized: "stats.sessions"))
            statCard(value: TimeFormatter.mmss(totalTime), label: String(localized: "stats.total_time"))
            statCard(value: TimeFormatter.mmss(bestRetentionEver), label: String(localized: "stats.best_retention"))
        }
    }

    private var statCardsRow2: some View {
        HStack(spacing: 12) {
            statCard(value: "\(streak.currentStreak)", label: String(localized: "stats.current_streak"))
            statCard(value: "\(streak.bestStreak)", label: String(localized: "stats.best_streak"))
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(Constants.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var chart: some View {
        if filteredSessions.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36))
                    .foregroundStyle(Constants.Palette.textSecondary.opacity(0.5))
                Text(String(localized: "stats.no_data"))
                    .font(.subheadline)
                    .foregroundStyle(Constants.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(Constants.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Chart(filteredSessions.reversed()) { session in
                AreaMark(
                    x: .value("Datum", session.date),
                    y: .value("Retention", session.bestRetention)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Constants.Palette.primaryTeal.opacity(0.35),
                            Constants.Palette.primaryTeal.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Datum", session.date),
                    y: .value("Retention", session.bestRetention)
                )
                .foregroundStyle(Constants.Palette.primaryTeal)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Datum", session.date),
                    y: .value("Retention", session.bestRetention)
                )
                .foregroundStyle(Constants.Palette.primaryTeal)
                .symbolSize(40)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Constants.Palette.textSecondary.opacity(0.15))
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(TimeFormatter.mmss(seconds))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Constants.Palette.textSecondary.opacity(0.1))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                        .font(.caption2)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Constants.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Constants.Palette.primaryTeal.opacity(0.5))
            Text(String(localized: "stats.no_sessions_yet"))
                .font(.subheadline)
                .foregroundStyle(Constants.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
