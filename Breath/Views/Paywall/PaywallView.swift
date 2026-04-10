import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    private let features: [String] = [
        "All breathing speeds",
        "All music & guidance styles",
        "Full history & charts",
        "Home screen widget",
        "Share results"
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(Constants.Palette.primaryTeal)
                }
            }

            Image(systemName: "lock.open.fill")
                .font(.system(size: 56))
                .foregroundStyle(Constants.Palette.primaryTeal)

            Text(String(localized: "paywall.title"))
                .font(.title.bold())
                .foregroundStyle(Constants.Palette.primaryTeal)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Constants.Palette.accentGreen)
                        Text(feature)
                    }
                }
            }

            Spacer()

            Button(action: {
                Task { try? await store.purchasePremium(); dismiss() }
            }) {
                Text("\(String(localized: "paywall.upgrade"))\(store.products.first.map { " — \($0.displayPrice)" } ?? "")")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Constants.Palette.primaryTeal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button(String(localized: "paywall.restore")) {
                Task { await store.restore() }
            }
            .foregroundStyle(Constants.Palette.textSecondary)
        }
        .padding()
    }
}
