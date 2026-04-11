import SwiftUI

struct SessionResultsView: View {
    @EnvironmentObject private var store: StoreService
    @State private var showPaywall = false

    let rounds: [RoundResult]
    let totalDuration: TimeInterval
    let configuration: SessionConfiguration
    var onDone: () -> Void

    private var shareText: String {
        let best = rounds.map(\.retentionTime).max() ?? 0
        let perRound = rounds
            .map { "Round \($0.roundNumber): \(TimeFormatter.mmss($0.retentionTime))" }
            .joined(separator: "\n")
        return """
        🌬️ Breath — \(rounds.count) rounds, total \(TimeFormatter.mmss(totalDuration))
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
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text(String(localized: "results.complete"))
                            .font(.title.bold())
                            .foregroundStyle(Constants.Palette.primaryTeal)
                        Text(String(format: NSLocalizedString("results.summary_total", comment: ""), rounds.count, TimeFormatter.mmss(totalDuration)))
                            .foregroundStyle(Constants.Palette.textSecondary)
                    }

                    HStack(spacing: 16) {
                        statCard(title: String(localized: "results.best"), value: TimeFormatter.mmss(best))
                        statCard(title: String(localized: "results.average"), value: TimeFormatter.mmss(average))
                    }

                    VStack(spacing: 0) {
                        ForEach(rounds) { round in
                            HStack {
                                Text(String(format: NSLocalizedString("results.round_label", comment: ""), round.roundNumber))
                                Spacer()
                                Text(TimeFormatter.mmss(round.retentionTime))
                                    .monospacedDigit()
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            if round.id != rounds.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .background(Constants.Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button(action: onDone) {
                        Text(String(localized: "results.done"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Constants.Palette.primaryTeal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    shareButton
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if store.isPremium {
            ShareLink(item: shareText) {
                Text(String(localized: "results.share"))
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

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Constants.Palette.textSecondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
