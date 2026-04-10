import Foundation

enum BreathingSpeed: String, Codable, CaseIterable, Identifiable {
    case slow
    case standard
    case fast

    var id: String { rawValue }

    var inhaleDuration: TimeInterval {
        switch self {
        case .slow: return 2.5
        case .standard: return 1.5
        case .fast: return 1.0
        }
    }

    var exhaleDuration: TimeInterval {
        switch self {
        case .slow: return 3.5
        case .standard: return 2.0
        case .fast: return 1.5
        }
    }

    var cycleDuration: TimeInterval {
        inhaleDuration + exhaleDuration
    }

    var localizedTitle: String {
        switch self {
        case .slow: return String(localized: "config.speed.slow")
        case .standard: return String(localized: "config.speed.standard")
        case .fast: return String(localized: "config.speed.fast")
        }
    }

    var isPremium: Bool {
        self != .standard
    }
}
