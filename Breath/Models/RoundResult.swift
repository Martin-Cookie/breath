import Foundation

struct RoundResult: Codable, Identifiable, Hashable {
    var id: Int { roundNumber }
    let roundNumber: Int
    let retentionTime: TimeInterval
    let recoveryHoldTime: TimeInterval
}
