import Foundation
import StoreKit
import SwiftUI

@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()

    static let premiumProductID = "cz.martinkoci.breath.pro"

    @Published private(set) var products: [Product] = []
    @Published var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: SettingsKey.isPremium) }
    }

    private var updatesTask: Task<Void, Never>?

    private init() {
        self.isPremium = UserDefaults.standard.bool(forKey: SettingsKey.isPremium)
        updatesTask = Task { await listenForTransactions() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.premiumProductID])
        } catch {
            print("StoreService load error: \(error)")
        }
    }

    func purchasePremium() async throws {
        guard let product = products.first else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                isPremium = true
                await transaction.finish()
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID {
                isPremium = true
                await transaction.finish()
            }
        }
    }
}
