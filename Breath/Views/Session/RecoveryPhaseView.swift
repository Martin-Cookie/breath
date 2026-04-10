import SwiftUI

struct RecoveryPhaseView: View {
    @ObservedObject var viewModel: SessionViewModel

    private var centerText: String {
        if viewModel.phase == .recoveryIn {
            return "…"
        }
        return "\(Int(viewModel.recoveryRemaining.rounded(.up)))"
    }

    var body: some View {
        BreathCircleView(
            scale: 1.0,
            color: Constants.Palette.accentGreen,
            label: "HOLD — 15s",
            centerText: centerText
        )
    }
}
