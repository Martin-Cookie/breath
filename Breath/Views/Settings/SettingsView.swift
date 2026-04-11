import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: StoreService

    @State private var showResetConfirm = false
    @State private var showRestartOnboardingConfirm = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                if !store.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            premiumCTARow
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section(String(localized: "settings.section.notifications")) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label(String(localized: "notifications.title"), systemImage: "bell.fill")
                    }
                }

                Section(String(localized: "settings.section.subscription")) {
                    if store.isPremium {
                        Label(String(localized: "settings.premium_active"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Constants.Palette.primaryTeal)
                    }
                    Button {
                        Task { await store.restore() }
                    } label: {
                        Label(String(localized: "settings.restore_purchases"), systemImage: "arrow.clockwise")
                    }
                }

                Section(String(localized: "settings.section.data")) {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label(String(localized: "settings.reset_data"), systemImage: "trash")
                    }
                    Button {
                        showRestartOnboardingConfirm = true
                    } label: {
                        Label(String(localized: "settings.restart_onboarding"), systemImage: "arrow.counterclockwise")
                    }
                }

                Section(String(localized: "settings.section.legal")) {
                    // TODO: replace with real privacy/terms URLs before App Store submission
                    Link(destination: URL(string: "https://breath.martinkoci.cz/privacy")!) {
                        Label(String(localized: "settings.privacy_policy"), systemImage: "hand.raised.fill")
                    }
                    // TODO: replace with real privacy/terms URLs before App Store submission
                    Link(destination: URL(string: "https://breath.martinkoci.cz/terms")!) {
                        Label(String(localized: "settings.terms_of_service"), systemImage: "doc.text.fill")
                    }
                    // TODO: replace with real support email before App Store submission
                    Link(destination: URL(string: "mailto:support@martinkoci.cz?subject=Breath%20support")!) {
                        Label(String(localized: "settings.contact_support"), systemImage: "envelope.fill")
                    }
                }

                Section(String(localized: "settings.section.about")) {
                    LabeledContent(String(localized: "settings.version"), value: appVersion)
                    Link(destination: URL(string: "https://www.wimhofmethod.com/")!) {
                        Label(String(localized: "settings.wim_hof_link"), systemImage: "arrow.up.forward.square")
                    }
                }

                Section {
                    Text(String(localized: "settings.safety_disclaimer"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "settings.done")) { dismiss() }
                }
            }
            .confirmationDialog(
                String(localized: "settings.reset_confirm_title"),
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.reset_confirm"), role: .destructive) {
                    resetAllData()
                }
                Button(String(localized: "session.cancel_continue"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings.reset_confirm_message"))
            }
            .confirmationDialog(
                String(localized: "settings.restart_onboarding_confirm_title"),
                isPresented: $showRestartOnboardingConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.restart_onboarding_confirm")) {
                    restartOnboarding()
                }
                Button(String(localized: "session.cancel_continue"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings.restart_onboarding_confirm_message"))
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var premiumCTARow: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "settings.premium_cta_title"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(String(localized: "settings.premium_cta_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Constants.Palette.primaryTeal, Constants.Palette.accentOrange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func resetAllData() {
        let descriptor = FetchDescriptor<Session>()
        if let sessions = try? modelContext.fetch(descriptor) {
            for session in sessions {
                modelContext.delete(session)
            }
            try? modelContext.save()
        }
        WidgetDataService.update(with: [])
        NotificationService.cancelAll()
    }

    private func restartOnboarding() {
        UserDefaults.standard.set(false, forKey: SettingsKey.hasSeenOnboarding)
        dismiss()
        // Onboarding will show on next app cold start; for immediate effect,
        // users can fully quit and relaunch. Add a note in the confirmation.
    }
}
