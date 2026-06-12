import Foundation
import SwiftData

enum DifficultyLevel: String, Codable, CaseIterable {
    case basic        = "Básico"
    case intermediate = "Intermedio"
    case advanced     = "Avanzado"
}

enum TextSource: String, Codable {
    case preloaded
    case camera
    case manual
}

@Model
final class LibraryItem {
    var id: UUID
    var title: String
    var body: String
    var level: DifficultyLevel
    var source: TextSource
    var createdAt: Date
    var lastReadAt: Date?
    var readCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        level: DifficultyLevel,
        source: TextSource = .preloaded,
        createdAt: Date = .now,
        lastReadAt: Date? = nil,
        readCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.level = level
        self.source = source
        self.createdAt = createdAt
        self.lastReadAt = lastReadAt
        self.readCount = readCount
    }
}
