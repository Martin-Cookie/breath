import SwiftUI

struct SessionResultsView: View {
    let rounds: [RoundResult]
    let totalDuration: TimeInterval
    let configuration: SessionConfiguration
    var onDone: () -> Void

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
                        Text("\(rounds.count) rounds • \(TimeFormatter.mmss(totalDuration)) total")
                            .foregroundStyle(Constants.Palette.textSecondary)
                    }

                    HStack(spacing: 16) {
                        statCard(title: String(localized: "results.best"), value: TimeFormatter.mmss(best))
                        statCard(title: String(localized: "results.average"), value: TimeFormatter.mmss(average))
                    }

                    VStack(spacing: 0) {
                        ForEach(rounds) { round in
                            HStack {
                                Text("Round \(round.roundNumber)")
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
                }
                .padding()
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
