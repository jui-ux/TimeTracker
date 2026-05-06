import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int   // cached on end
    var type: String           // ProjectType.rawValue — SwiftData needs String for enum
    var notes: String
    @Relationship(deleteRule: .nullify)
    var client: Client?

    // Pause support — scalar types only (SwiftData does not support Array attributes)
    var pausedSecondsAccumulated: Int  // completed pause intervals
    var currentPauseStart: Double      // Unix timestamp; 0 = not paused

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        type: ProjectType = .untyped,
        notes: String = "",
        client: Client
    ) {
        self.id                       = id
        self.startedAt                = startedAt
        self.endedAt                  = nil
        self.durationSeconds          = 0
        self.type                     = type.rawValue
        self.notes                    = notes
        self.client                   = client
        self.pausedSecondsAccumulated = 0
        self.currentPauseStart        = 0
    }

    var projectType: ProjectType {
        get { ProjectType(rawValue: type) ?? .untyped }
        set { type = newValue.rawValue }
    }

    var isRunning: Bool { endedAt == nil }
    var isPaused:  Bool { currentPauseStart > 0 }

    // Total paused seconds including any in-progress pause
    var pausedSeconds: Int {
        let inProgress = isPaused ? Int(Date.now.timeIntervalSince1970 - currentPauseStart) : 0
        return pausedSecondsAccumulated + inProgress
    }
}
