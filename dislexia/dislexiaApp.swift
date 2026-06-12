import SwiftUI
import SwiftData

@main
struct dislexiaApp: App {
    // Demo: el onboarding se muestra en cada arranque a propósito
    @State private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    LibraryView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
            .environment(AppPreferences.shared)
            .modelContainer(LibraryStore.shared.container)
            .task { LibraryStore.shared.seedIfNeeded() }
        }
    }
}
