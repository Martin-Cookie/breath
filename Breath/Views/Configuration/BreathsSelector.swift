import SwiftUI

struct BreathsSelector: View {
    @Binding var selection: Int

    var body: some View {
        HStack {
            Text(String(localized: "config.breaths"))
                .foregroundStyle(Constants.Palette.primaryTeal)
            Spacer()
            ForEach(Constants.Session.breathOptions, id: \.self) { value in
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
