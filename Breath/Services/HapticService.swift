import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
protocol HapticServiceProtocol {
    func impact(_ style: HapticService.Style)
    func notify(_ type: HapticService.Notification)
}

@MainActor
final class HapticService: HapticServiceProtocol {
    static let shared = HapticService()

    enum Style {
        case soft, light, medium, heavy
    }

    enum Notification {
        case success, warning, error
    }

    private init() {}

    func impact(_ style: Style) {
        #if canImport(UIKit)
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch style {
            case .soft: return .soft
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }()
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
        #endif
    }

    func notify(_ type: Notification) {
        #if canImport(UIKit)
        let notificationType: UINotificationFeedbackGenerator.FeedbackType = {
            switch type {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }()
        UINotificationFeedbackGenerator().notificationOccurred(notificationType)
        #endif
    }
}
