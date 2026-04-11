import SwiftUI

struct RoundResultView: View {
    let roundNumber: Int
    let totalRounds: Int
    let retention: TimeInterval
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 32) {
            Text(String(format: NSLocalizedString("session.round_label", comment: ""), roundNumber, totalRounds))
                .font(.system(size: 14, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Constants.Palette.textSecondary)

            ZStack {
                Circle()
                    .fill(Constants.Palette.primaryTeal.opacity(0.1))
                    .frame(width: 220, height: 220)
                Text(TimeFormatter.mmss(retention))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .monospacedDigit()
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }

            Text(String(localized: "session.tap_to_continue"))
                .font(.caption)
                .foregroundStyle(Constants.Palette.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
