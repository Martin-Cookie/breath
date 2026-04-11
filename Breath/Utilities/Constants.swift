import Foundation
import SwiftUI

enum Constants {
    enum Session {
        /// Doba recovery hold fáze v sekundách.
        static let recoveryHoldDuration: TimeInterval = 15
        /// Jak dlouho se zobrazuje mezivýsledek kola (při auto-pokračování).
        static let roundResultAutoAdvance: TimeInterval = 4
        /// Doporučené hodnoty pro inline pickery.
        static let roundOptions = [2, 3, 4]
        static let breathOptions = [30, 35, 40]
    }

    enum Freemium {
        static let freeHistoryDays = 7
        static let freeMusicTracks: Set<String> = ["sweet_and_spicy"]
        static let freeGuidanceStyles: Set<String> = ["classic"]
        static let fallbackPriceLabel = "99 Kč"
    }

    enum Palette {
        static let primaryTeal = Color(red: 0x0d / 255, green: 0x4f / 255, blue: 0x52 / 255)
        static let tealLight = Color(red: 0x0d / 255, green: 0x73 / 255, blue: 0x77 / 255)
        static let accentOrange = Color(red: 0xd4 / 255, green: 0x78 / 255, blue: 0x2a / 255)
        static let accentGreen = Color(red: 0x3a / 255, green: 0xab / 255, blue: 0x6a / 255)
        static let textSecondary = Color(red: 0x6b / 255, green: 0x9b / 255, blue: 0x9e / 255)
        static let surface = Color(red: 0xf5 / 255, green: 0xf8 / 255, blue: 0xf8 / 255)
    }

    enum AppGroup {
        static let identifier = "group.cz.martinkoci.breath"
    }
}
