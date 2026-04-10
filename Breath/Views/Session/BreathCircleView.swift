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
            // Vnější glow — intenzita roste se scale.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.35), color.opacity(0.0)],
                        center: .center,
                        startRadius: 60,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 340)
                .scaleEffect(scale)
                .blur(radius: 16)

            // Základní výplň.
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 280, height: 280)
                .scaleEffect(scale)
                .shadow(color: color.opacity(0.55 * Double(scale)), radius: 50 * scale, x: 0, y: 0)

            // Obrys.
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 280, height: 280)
                .scaleEffect(scale)

            // Obsah (zůstává staticky centrovaný, bez scale).
            VStack(spacing: 10) {
                Text(centerText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(Constants.Palette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
