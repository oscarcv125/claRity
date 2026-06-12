import SwiftUI
import SwiftData

@main
struct dislexiaApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(AppPreferences.shared)
                .modelContainer(LibraryStore.shared.container)
                .task { LibraryStore.shared.seedIfNeeded() }
        }
    }
}
