import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: SessionViewModel
    @State private var showCancelDialog = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                phaseContent
                Spacer()
                Spacer()
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.phase == .retention {
                viewModel.tapToBreathe()
            } else if viewModel.phase == .roundResult {
                viewModel.advanceFromRoundResult()
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .completed {
                persistSession()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.phase == .completed },
            set: { _ in }
        )) {
            SessionResultsView(
                rounds: viewModel.roundResults,
                totalDuration: viewModel.sessionDuration,
                configuration: viewModel.configuration
            ) {
                dismiss()
            }
        }
        .confirmationDialog(
            "Opravdu chcete ukončit cvičení?",
            isPresented: $showCancelDialog,
            titleVisibility: .visible
        ) {
            Button("Ukončit", role: .destructive) {
                viewModel.cancel()
                dismiss()
            }
            Button("Pokračovat", role: .cancel) {}
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { showCancelDialog = true }) {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Constants.Palette.primaryTeal)
            }
            Spacer()
            Text("Round \(viewModel.currentRound)/\(viewModel.configuration.rounds)")
                .font(.headline)
                .foregroundStyle(Constants.Palette.primaryTeal)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .idle, .breathing:
            BreathingPhaseView(viewModel: viewModel)
        case .retention:
            RetentionPhaseView(viewModel: viewModel)
        case .recoveryIn, .recoveryHold:
            RecoveryPhaseView(viewModel: viewModel)
        case .roundResult:
            RoundResultView(
                roundNumber: viewModel.currentRound,
                totalRounds: viewModel.configuration.rounds,
                retention: viewModel.roundResults.last?.retentionTime ?? 0
            )
        case .completed, .cancelled:
            EmptyView()
        }
    }

    private func persistSession() {
        let session = Session(
            speed: viewModel.configuration.speed,
            totalRounds: viewModel.configuration.rounds,
            breathsPerRound: viewModel.configuration.breathsBeforeRetention,
            rounds: viewModel.roundResults,
            totalDuration: viewModel.sessionDuration
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}
