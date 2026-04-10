import SwiftUI

struct BreathingPhaseView: View {
    @ObservedObject var viewModel: SessionViewModel

    private var scale: CGFloat {
        viewModel.breathStep == .inhale ? 1.0 : 0.5
    }

    private var duration: Double {
        viewModel.breathStep == .inhale
            ? viewModel.configuration.speed.inhaleDuration
            : viewModel.configuration.speed.exhaleDuration
    }

    private var label: String {
        viewModel.breathStep == .inhale
            ? String(localized: "session.breathe_in")
            : String(localized: "session.breathe_out")
    }

    var body: some View {
        BreathCircleView(
            scale: scale,
            color: Constants.Palette.tealLight,
            label: label,
            centerText: "\(viewModel.remainingBreaths)"
        )
        .animation(.easeInOut(duration: duration), value: viewModel.breathStep)
    }
}
