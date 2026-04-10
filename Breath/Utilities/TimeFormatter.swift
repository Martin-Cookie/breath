import Foundation

enum TimeFormatter {
    /// Formátuje čas jako mm:ss. Pro hodnoty ≥ 1h doplní hodiny.
    static func mmss(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Rozdíl mezi dvěma retention časy jako `+0:15` nebo `-0:03`.
    static func signedDiff(_ diff: TimeInterval) -> String {
        let sign = diff >= 0 ? "+" : "-"
        return sign + mmss(abs(diff))
    }
}
