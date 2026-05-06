import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String   // hex
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Session.client)
    var sessions: [Session]

    init(id: UUID = UUID(), name: String, color: String, createdAt: Date = .now, sortOrder: Int = 0) {
        self.id        = id
        self.name      = name
        self.color     = color
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.sessions  = []
    }
}
