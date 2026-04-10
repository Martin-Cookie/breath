import SwiftUI
import SwiftData

@main
struct BreathApp: App {
    @StateObject private var store = StoreService.shared
    @AppStorage(SettingsKey.hasSeenOnboarding) private var hasSeenOnboarding: Bool = false

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITestResetState") {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            UserDefaults.standard.set(false, forKey: SettingsKey.hasSeenOnboarding)
        }
        if args.contains("-UITestSkipOnboarding") {
            UserDefaults.standard.set(true, forKey: SettingsKey.hasSeenOnboarding)
        }
        #endif
    }

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
