import SwiftUI

/// Animovaný kruh používaný ve všech fázích cvičení.
/// Scale (0.5–1.0), barvu a glow řídí rodičovský View podle fáze.
struct BreathCircleView: View {
    let scale: CGFloat
    let color: Color
    let label: String?
    let centerText: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 280, height: 280)
                .scaleEffect(scale)
                .shadow(color: color.opacity(0.5), radius: 40 * scale, x: 0, y: 0)

            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 280, height: 280)
                .scaleEffect(scale)

            VStack(spacing: 8) {
                Text(centerText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .monospacedDigit()
                if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(Constants.Palette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
