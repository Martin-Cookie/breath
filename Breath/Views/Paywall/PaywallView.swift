import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseInProgress = false
    @State private var errorMessage: String?

    private var features: [(icon: String, title: String)] {
        [
            ("speedometer", String(localized: "paywall.feature.speeds")),
            ("music.note", String(localized: "paywall.feature.music_guidance")),
            ("chart.line.uptrend.xyaxis", String(localized: "paywall.feature.history")),
            ("square.grid.2x2.fill", String(localized: "paywall.feature.widget")),
            ("square.and.arrow.up", String(localized: "paywall.feature.share"))
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Constants.Palette.primaryTeal.opacity(0.12), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.title) { feature in
                            HStack(spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundStyle(Constants.Palette.accentGreen)
                                    .frame(width: 32)
                                Text(feature.title)
                                    .font(.body)
                                    .foregroundStyle(Constants.Palette.primaryTeal)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                }

                footer
            }
        }
        .alert(String(localized: "paywall.error_title"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "paywall.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Constants.Palette.textSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(Constants.Palette.primaryTeal.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "sparkles")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(Constants.Palette.primaryTeal)
            }

            Text(String(localized: "paywall.title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Constants.Palette.primaryTeal)

            Text(String(localized: "paywall.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: purchase) {
                HStack {
                    if purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Constants.Palette.primaryTeal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Constants.Palette.primaryTeal.opacity(0.25), radius: 12, y: 4)
            }
            .disabled(purchaseInProgress || store.products.isEmpty)

            Button(String(localized: "paywall.restore")) {
                Task { await store.restore() }
            }
            .font(.footnote)
            .foregroundStyle(Constants.Palette.textSecondary)

            Text(String(localized: "paywall.legal"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private var purchaseButtonTitle: String {
        if let price = store.products.first?.displayPrice {
            return String(format: String(localized: "paywall.upgrade_with_price"), price)
        }
        return String(localized: "paywall.upgrade")
    }

    private func purchase() {
        purchaseInProgress = true
        Task {
            do {
                try await store.purchasePremium()
                await MainActor.run {
                    purchaseInProgress = false
                    if store.isPremium {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    purchaseInProgress = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
