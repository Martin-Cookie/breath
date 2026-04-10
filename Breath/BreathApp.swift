import SwiftUI
import SwiftData

@main
struct BreathApp: App {
    @StateObject private var store = StoreService.shared
    @AppStorage(SettingsKey.hasSeenOnboarding) private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ConfigurationView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .tint(Constants.Palette.primaryTeal)
            .task { await store.loadProducts() }
        }
        .modelContainer(for: Session.self)
    }
}
