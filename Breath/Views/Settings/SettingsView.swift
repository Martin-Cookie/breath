import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var store: StoreService

    @State private var showResetConfirm = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
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
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label(String(localized: "settings.unlock_premium"), systemImage: "star.fill")
                        }
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
                }

                Section(String(localized: "settings.section.about")) {
                    LabeledContent(String(localized: "settings.version"), value: appVersion)
                    Link(destination: URL(string: "https://www.wimhofmethod.com/")!) {
                        Label(String(localized: "settings.wim_hof_link"), systemImage: "link")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
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
}
