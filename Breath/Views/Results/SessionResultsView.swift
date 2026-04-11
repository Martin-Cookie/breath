import SwiftUI

struct SessionResultsView: View {
    @EnvironmentObject private var store: StoreService
    @State private var showPaywall = false
    @State private var appeared = false

    let rounds: [RoundResult]
    let totalDuration: TimeInterval
    let configuration: SessionConfiguration
    var onDone: () -> Void

    private var shareText: String {
        let perRound = rounds
            .map { "Round \($0.roundNumber): \(TimeFormatter.mmss($0.retentionTime))" }
            .joined(separator: "\n")
        return """
        Breath — \(rounds.count) rounds, total \(TimeFormatter.mmss(totalDuration))
        Best retention: \(TimeFormatter.mmss(best))
        \(perRound)
        """
    }

    private var best: TimeInterval {
        rounds.map(\.retentionTime).max() ?? 0
    }

    private var average: TimeInterval {
        guard !rounds.isEmpty else { return 0 }
        return rounds.map(\.retentionTime).reduce(0, +) / Double(rounds.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Constants.Palette.accentGreen.opacity(0.12), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroCelebration

                        HStack(spacing: 12) {
                            statCard(
                                icon: "crown.fill",
                                tint: Constants.Palette.accentOrange,
                                title: String(localized: "results.best"),
                                value: TimeFormatter.mmss(best)
                            )
                            statCard(
                                icon: "equal.circle.fill",
                                tint: Constants.Palette.tealLight,
                                title: String(localized: "results.average"),
                                value: TimeFormatter.mmss(average)
                            )
                        }

                        roundsList

                        Button(action: onDone) {
                            Text(String(localized: "results.done"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Constants.Palette.primaryTeal)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Constants.Palette.primaryTeal.opacity(0.25), radius: 12, y: 4)
                        }

                        shareButton
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - Hero

    private var heroCelebration: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Constants.Palette.accentGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1 : 0.7)
                Circle()
                    .fill(LinearGradient(
                        colors: [Constants.Palette.accentGreen, Constants.Palette.tealLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 92, height: 92)
                    .shadow(color: Constants.Palette.accentGreen.opacity(0.35), radius: 16, y: 6)
                    .scaleEffect(appeared ? 1 : 0.5)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(appeared ? 1 : 0.1)
                    .opacity(appeared ? 1 : 0)
            }
            .frame(height: 130)

            Text(String(localized: "results.complete"))
                .font(.title.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)

            Text(String(format: NSLocalizedString("results.summary_total", comment: ""), rounds.count, TimeFormatter.mmss(totalDuration)))
                .font(.subheadline)
                .foregroundStyle(Constants.Palette.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Stat card

    private func statCard(icon: String, tint: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(Constants.Palette.textSecondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Rounds list

    private var roundsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(roundCircleColor(for: round).opacity(0.15))
                            .frame(width: 34, height: 34)
                        Text("\(round.roundNumber)")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(roundCircleColor(for: round))
                            .monospacedDigit()
                    }

                    Text(String(format: NSLocalizedString("results.round_label", comment: ""), round.roundNumber))
                        .font(.subheadline)
                        .foregroundStyle(Constants.Palette.primaryTeal)

                    Spacer()

                    Text(TimeFormatter.mmss(round.retentionTime))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Constants.Palette.primaryTeal)

                    if round.retentionTime == best && rounds.count > 1 {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(Constants.Palette.accentOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if index < rounds.count - 1 {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func roundCircleColor(for round: RoundResult) -> Color {
        round.retentionTime == best && rounds.count > 1
            ? Constants.Palette.accentOrange
            : Constants.Palette.primaryTeal
    }

    // MARK: - Share

    @ViewBuilder
    private var shareButton: some View {
        if store.isPremium {
            ShareLink(item: shareText) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(String(localized: "results.share"))
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Constants.Palette.surface)
                .foregroundStyle(Constants.Palette.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        } else {
            Button(action: { showPaywall = true }) {
                HStack {
                    Image(systemName: "lock.fill")
                    Text(String(localized: "results.share"))
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Constants.Palette.surface)
                .foregroundStyle(Constants.Palette.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
