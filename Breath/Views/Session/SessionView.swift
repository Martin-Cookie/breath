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
                    .id(viewModel.phase)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
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
            String(localized: "session.cancel_confirm"),
            isPresented: $showCancelDialog,
            titleVisibility: .visible
        ) {
            Button(String(localized: "session.cancel_end"), role: .destructive) {
                viewModel.cancel()
                dismiss()
            }
            Button(String(localized: "session.cancel_continue"), role: .cancel) {}
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
            Text(String(format: String(localized: "session.round_of"), viewModel.currentRound, viewModel.configuration.rounds))
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

        // Aktualizuj sdílená data pro widget.
        let descriptor = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allSessions = (try? modelContext.fetch(descriptor)) ?? [session]
        WidgetDataService.update(with: allSessions)

        // Přeplánuj streak warning — po dokončení dnešní session ho smazat;
        // pokud uživatel další den nebude cvičit, warning se přeplánuje při startu app.
        let info = StreakService.compute(from: allSessions)
        NotificationService.scheduleStreakWarning(
            streakCount: info.currentStreak,
            lastSessionDate: info.lastSessionDate
        )
    }
}
