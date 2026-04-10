import SwiftUI

struct SpeedSelector: View {
    @Binding var selection: BreathingSpeed

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(BreathingSpeed.allCases) { speed in
                Text(speed.localizedTitle).tag(speed)
            }
        }
        .pickerStyle(.segmented)
    }
}
