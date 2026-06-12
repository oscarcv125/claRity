import SwiftData
import Foundation

@MainActor
final class LibraryStore {
    static let shared = LibraryStore()

    let container: ModelContainer

    private init() {
        let schema = Schema([LibraryItem.self])
        let config = ModelConfiguration("DislexIA", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }

    func seedIfNeeded() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<LibraryItem>())) ?? 0
        guard count == 0 else { return }
        for item in PreloadedLibrary.items {
            context.insert(item)
        }
        try? context.save()
    }

    func save(title: String, body: String, level: DifficultyLevel, source: TextSource) {
        let item = LibraryItem(title: title, body: body, level: level, source: source)
        container.mainContext.insert(item)
        try? container.mainContext.save()
    }

    func markRead(_ item: LibraryItem) {
        item.lastReadAt = .now
        item.readCount += 1
        try? container.mainContext.save()
    }

    func delete(_ item: LibraryItem) {
        container.mainContext.delete(item)
        try? container.mainContext.save()
    }
}
