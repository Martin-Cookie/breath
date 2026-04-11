import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseInProgress = false
    @State private var errorMessage: String?

    private var features: [(icon: String, title: String, subtitle: String)] {
        [
            ("speedometer",
             String(localized: "paywall.feature.speeds"),
             String(localized: "paywall.feature.speeds_subtitle")),
            ("music.note",
             String(localized: "paywall.feature.music_guidance"),
             String(localized: "paywall.feature.music_guidance_subtitle")),
            ("chart.line.uptrend.xyaxis",
             String(localized: "paywall.feature.history"),
             String(localized: "paywall.feature.history_subtitle")),
            ("square.grid.2x2.fill",
             String(localized: "paywall.feature.widget"),
             String(localized: "paywall.feature.widget_subtitle")),
            ("square.and.arrow.up",
             String(localized: "paywall.feature.share"),
             String(localized: "paywall.feature.share_subtitle"))
        ]
    }

    private struct CompareRow {
        let label: String
        let free: String
        let pro: String
    }

    private var compareRows: [CompareRow] {
        [
            CompareRow(label: String(localized: "paywall.compare.row.speeds"),
                       free: "1", pro: "3"),
            CompareRow(label: String(localized: "paywall.compare.row.music"),
                       free: String(localized: "paywall.compare.value.music_free"),
                       pro: String(localized: "paywall.compare.value.music_pro")),
            CompareRow(label: String(localized: "paywall.compare.row.history"),
                       free: String(localized: "paywall.compare.value.history_free"),
                       pro: String(localized: "paywall.compare.value.history_pro")),
            CompareRow(label: String(localized: "paywall.compare.row.widget"),
                       free: "✗", pro: "✓"),
            CompareRow(label: String(localized: "paywall.compare.row.share"),
                       free: "✗", pro: "✓")
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
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(features, id: \.title) { feature in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: feature.icon)
                                        .font(.subheadline)
                                        .foregroundStyle(Constants.Palette.accentGreen)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(feature.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Constants.Palette.primaryTeal)
                                        Text(feature.subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }

                        comparisonBlock
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
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
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Constants.Palette.textSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Constants.Palette.tealLight, Constants.Palette.primaryTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .offset(x: -16)
                Circle()
                    .fill(LinearGradient(
                        colors: [Constants.Palette.accentOrange, Constants.Palette.accentOrange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .offset(x: 16)
                    .blendMode(.multiply)
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(height: 84)

            Text(String(localized: "paywall.title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Constants.Palette.primaryTeal)

            Text(String(localized: "paywall.subtitle"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var comparisonBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "paywall.compare.title"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Constants.Palette.primaryTeal)

            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "paywall.compare.feature"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(localized: "paywall.compare.free"))
                        .frame(width: 60, alignment: .center)
                    Text(String(localized: "paywall.compare.pro"))
                        .frame(width: 60, alignment: .center)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.vertical, 5)

                Divider()

                ForEach(Array(compareRows.enumerated()), id: \.offset) { idx, row in
                    HStack {
                        Text(row.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Constants.Palette.primaryTeal)
                        Text(row.free)
                            .frame(width: 60, alignment: .center)
                            .foregroundStyle(.secondary)
                        Text(row.pro)
                            .frame(width: 60, alignment: .center)
                            .foregroundStyle(Constants.Palette.accentOrange)
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                    if idx < compareRows.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .background(Constants.Palette.accentOrange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Constants.Palette.accentOrange.opacity(0.3), radius: 12, y: 4)
            }
            .disabled(purchaseInProgress)

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
        return String(format: String(localized: "paywall.upgrade_with_price"), Constants.Freemium.fallbackPriceLabel)
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
