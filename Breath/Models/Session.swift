import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    var speedRaw: String
    var totalRounds: Int
    var breathsPerRound: Int
    var roundsData: Data
    var totalDuration: TimeInterval

    var speed: BreathingSpeed {
        get { BreathingSpeed(rawValue: speedRaw) ?? .standard }
        set { speedRaw = newValue.rawValue }
    }

    var rounds: [RoundResult] {
        get {
            (try? JSONDecoder().decode([RoundResult].self, from: roundsData)) ?? []
        }
        set {
            roundsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var bestRetention: TimeInterval {
        rounds.map(\.retentionTime).max() ?? 0
    }

    var averageRetention: TimeInterval {
        guard !rounds.isEmpty else { return 0 }
        return rounds.map(\.retentionTime).reduce(0, +) / Double(rounds.count)
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        speed: BreathingSpeed,
        totalRounds: Int,
        breathsPerRound: Int,
        rounds: [RoundResult],
        totalDuration: TimeInterval
    ) {
        self.id = id
        self.date = date
        self.speedRaw = speed.rawValue
        self.totalRounds = totalRounds
        self.breathsPerRound = breathsPerRound
        self.roundsData = (try? JSONEncoder().encode(rounds)) ?? Data()
        self.totalDuration = totalDuration
    }
}
