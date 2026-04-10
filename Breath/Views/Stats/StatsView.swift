import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: StoreService
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var period: Period = .week
    @State private var showPaywall = false

    enum Period: String, CaseIterable, Identifiable {
        case week = "7d"
        case month = "30d"
        case all = "Vše"
        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return nil
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statCards

                Text("Retention Time")
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
                            Text(p.rawValue)
                            if p.isPremium && !store.isPremium {
                                Image(systemName: "lock.fill")
                            }
                        }
                        .tag(p)
                    }
                }
                .pickerStyle(.segmented)

                Text("Historie")
                    .font(.headline)
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .padding(.top, 8)

                ForEach(filteredSessions) { session in
                    SessionRowView(session: session)
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

    private var statCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(sessions.count)", label: String(localized: "stats.sessions"))
            statCard(value: TimeFormatter.mmss(totalTime), label: String(localized: "stats.total_time"))
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
            Text("Žádná data")
                .foregroundStyle(Constants.Palette.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(Constants.Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Chart(filteredSessions.reversed()) { session in
                LineMark(
                    x: .value("Datum", session.date),
                    y: .value("Retention", session.bestRetention)
                )
                .foregroundStyle(Constants.Palette.primaryTeal)
                PointMark(
                    x: .value("Datum", session.date),
                    y: .value("Retention", session.bestRetention)
                )
                .foregroundStyle(Constants.Palette.primaryTeal)
            }
            .frame(height: 180)
            .padding()
            .background(Constants.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
