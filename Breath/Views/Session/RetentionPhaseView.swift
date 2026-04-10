import SwiftUI

struct RetentionPhaseView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var pulse: CGFloat = 0.95

    var body: some View {
        VStack(spacing: 24) {
            BreathCircleView(
                scale: pulse,
                color: Constants.Palette.accentOrange,
                label: String(localized: "session.hold"),
                centerText: TimeFormatter.mmss(viewModel.retentionElapsed)
            )
            Text(String(localized: "session.tap_to_breathe"))
                .font(.body)
                .foregroundStyle(Constants.Palette.textSecondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
        }
    }
}
