import SwiftUI
import SwiftData

@main
struct BreathApp: App {
    @StateObject private var store = StoreService.shared

    var body: some Scene {
        WindowGroup {
            ConfigurationView()
                .environmentObject(store)
                .tint(Constants.Palette.primaryTeal)
                .task { await store.loadProducts() }
        }
        .modelContainer(for: Session.self)
    }
}
