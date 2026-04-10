import SwiftUI

struct RetentionPhaseView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var pulse: CGFloat = 0.5

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
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = 0.55
            }
        }
    }
}
