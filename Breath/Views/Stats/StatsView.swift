import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss
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

    private var hasTodaySession: Bool {
        guard let latest = sessions.first else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                todayHero

                statCardsRow1
                statCardsRow2

                HStack {
                    Text(String(localized: "stats.retention_chart"))
                        .font(.headline)
                        .foregroundStyle(Constants.Palette.primaryTeal)
                    Spacer()
                    periodPicker
                }

                chart

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
        .toolbar {
            if !sessions.isEmpty && store.isPremium {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareSummary) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Today hero

    private var todayHero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: heroGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: heroIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(heroTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                Text(heroSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !hasTodaySession {
                Button(action: { dismiss() }) {
                    Text(String(localized: "stats.today.cta"))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Constants.Palette.accentOrange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var heroGradientColors: [Color] {
        if hasTodaySession {
            return [Constants.Palette.accentGreen, Constants.Palette.accentGreen.opacity(0.7)]
        }
        if streak.currentStreak > 0 {
            return [Constants.Palette.accentOrange, Constants.Palette.accentOrange.opacity(0.7)]
        }
        return [Constants.Palette.primaryTeal, Constants.Palette.tealLight]
    }

    private var heroIcon: String {
        if hasTodaySession { return "checkmark.circle.fill" }
        if streak.currentStreak > 0 { return "flame.fill" }
        return "leaf.fill"
    }

    private var heroTitle: String {
        if hasTodaySession {
            return String(localized: "stats.today.done")
        }
        if streak.currentStreak > 0 {
            return String(format: String(localized: "stats.today.streak"), streak.currentStreak)
        }
        return String(localized: "stats.today.empty")
    }

    private var heroSubtitle: String {
        if hasTodaySession {
            return String(localized: "stats.today.done_subtitle")
        }
        return String(localized: "stats.today.empty_subtitle")
    }

    // MARK: - Stat cards

    private var statCardsRow1: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "figure.mind.and.body",
                tint: Constants.Palette.primaryTeal,
                value: "\(sessions.count)",
                label: String(localized: "stats.sessions")
            )
            statCard(
                icon: "clock.fill",
                tint: Constants.Palette.tealLight,
                value: TimeFormatter.mmss(totalTime),
                label: String(localized: "stats.total_time")
            )
            statCard(
                icon: "timer",
                tint: Constants.Palette.accentOrange,
                value: TimeFormatter.mmss(bestRetentionEver),
                label: String(localized: "stats.best_retention")
            )
        }
    }

    private var statCardsRow2: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "flame.fill",
                tint: Constants.Palette.accentOrange,
                value: "\(streak.currentStreak)",
                label: String(localized: "stats.current_streak")
            )
            statCard(
                icon: "trophy.fill",
                tint: Constants.Palette.accentGreen,
                value: "\(streak.bestStreak)",
                label: String(localized: "stats.best_streak")
            )
        }
    }

    private func statCard(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(height: 18)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

    // MARK: - Period picker

    private var periodPicker: some View {
        Menu {
            ForEach(Period.allCases) { p in
                Button(action: {
                    if p.isPremium && !store.isPremium {
                        showPaywall = true
                    } else {
                        period = p
                    }
                }) {
                    HStack {
                        Text(p.localizedTitle)
                        if p.isPremium && !store.isPremium {
                            Image(systemName: "lock.fill")
                        }
                        if period == p {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(period.localizedTitle)
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Constants.Palette.primaryTeal)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Constants.Palette.primaryTeal.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        if filteredSessions.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36))
                    .foregroundStyle(Constants.Palette.textSecondary.opacity(0.5))
                Text(String(localized: "stats.no_data"))
                    .font(.subheadline)
                    .foregroundStyle(Constants.Palette.textSecondary)
                Button(action: { dismiss() }) {
                    Text(String(localized: "stats.empty.cta"))
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Constants.Palette.primaryTeal)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(.vertical, 20)
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
            Image(systemName: "clock.arrow.circlepath")
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

    // MARK: - Share

    private var shareSummary: String {
        String(
            format: String(localized: "stats.share_summary"),
            sessions.count,
            TimeFormatter.mmss(totalTime),
            TimeFormatter.mmss(bestRetentionEver),
            streak.currentStreak
        )
    }
}
