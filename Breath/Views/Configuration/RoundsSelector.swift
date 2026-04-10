import SwiftUI

struct RoundsSelector: View {
    @Binding var selection: Int

    var body: some View {
        HStack {
            Text(String(localized: "config.rounds"))
                .foregroundStyle(Constants.Palette.primaryTeal)
            Spacer()
            ForEach(Constants.Session.roundOptions, id: \.self) { value in
                Button(action: { selection = value }) {
                    Text("\(value)")
                        .font(.headline)
                        .frame(width: 44, height: 36)
                        .background(selection == value ? Constants.Palette.primaryTeal : Constants.Palette.surface)
                        .foregroundStyle(selection == value ? .white : Constants.Palette.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Kompaktní varianta pro sdílený řádek s `BreathsSelector`.
struct RoundsBreathsRow: View {
    @Binding var rounds: Int
    @Binding var breaths: Int

    var body: some View {
        HStack(spacing: 10) {
            group(
                label: String(localized: "config.rounds"),
                options: Constants.Session.roundOptions,
                selection: $rounds
            )
            Divider().frame(height: 28)
            group(
                label: String(localized: "config.breaths"),
                options: Constants.Session.breathOptions,
                selection: $breaths
            )
        }
    }

    private func group(label: String, options: [Int], selection: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(Constants.Palette.primaryTeal)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            ForEach(options, id: \.self) { value in
                Button(action: { selection.wrappedValue = value }) {
                    Text("\(value)")
                        .font(.body.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(selection.wrappedValue == value ? Constants.Palette.primaryTeal : Constants.Palette.surface)
                        .foregroundStyle(selection.wrappedValue == value ? .white : Constants.Palette.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
