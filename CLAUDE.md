# ClaRity — Claude Code Project Context

## Project identity
- **App**: ClaRity — accessibility reader for people with dyslexia
- **Platform**: iOS 18+ / iPadOS 18+
- **Language**: Swift 6
- **UI**: SwiftUI 6 with iOS 26 Liquid Glass design language
- **Architecture**: MVVM with @Observable (NO ObservableObject, NO Combine)
- **AI**: Foundation Models on-device (FoundationModels framework, iOS 18+)
- **Persistence**: SwiftData
- **No third-party SDKs** — Apple frameworks only + OpenDyslexic .otf font

## Build system
Use XcodeBuildMCP for ALL Xcode operations. Never use raw xcodebuild commands.
- Build: `mcp__xcodebuildmcp__build_sim_name_proj`
- Run:   `mcp__xcodebuildmcp__build_run_sim_name_proj`
- Test:  `mcp__xcodebuildmcp__test_sim_name_proj`
- Clean: `mcp__xcodebuildmcp__clean`

## Swift coding rules (non-negotiable)
- Swift 6 strict concurrency — every async call on `@MainActor` unless explicitly off
- `@Observable` for all ViewModels — NEVER `ObservableObject`
- `async/await` everywhere — NO Combine publishers
- `guard` for early exits — NO nested if-let chains
- Structs over classes unless identity/mutation semantics required
- No force unwrap `!` anywhere — use `guard let` or `if let`
- 4-space indentation, PascalCase types, camelCase properties/methods
- Every SwiftUI view must have a `#Preview` macro at the bottom
- Extract any view body exceeding 80 lines into sub-components

## SwiftUI patterns
- `NavigationStack` with typed `Route` enum — never `NavigationView`
- `@State private var` for local view state only
- `@Environment` for dependency injection
- `@Bindable` for bindings to @Observable objects
- `.task {}` for async work triggered by view appearance
- `withAnimation(.spring(duration: 0.35))` as default animation
- Minimum tap target 44×44pt on all interactive elements

## iOS 26 Liquid Glass design rules
- Apply `.glassEffect()` to floating controls, cards, and bottom bars
- Use `GlassEffectContainer` when grouping 2+ glass elements
- `.glassEffect(.regular.interactive())` on buttons that need press feedback
- `.glassEffect(.regular.tint(.accentColor))` only for primary CTA — not decoration
- Use `.backgroundExtensionEffect()` for edge-to-edge bleed on scroll containers
- Morphing transitions via `.glassEffectID()` + `Namespace`
- NEVER stack glass on glass — maintain clear visual hierarchy
- Backgrounds: use `.ultraThinMaterial` or custom pastel colors, NOT pure white/black

## Accessibility (mandatory, not optional)
- Every interactive element has `accessibilityLabel`
- Compound elements: `.accessibilityElement(children: .combine)`
- Selection state: `.accessibilityAddTraits(.isSelected)` where relevant
- Haptic feedback on all major state changes (UIImpactFeedbackGenerator)
- `.accessibilityReduceMotion` check before every animation
- Dynamic Type respected everywhere (exceptions: ReaderView user-controlled font)
- WCAG AA contrast on all color pairs

## Target devices
- **Primary simulator**: iPhone 17 Pro
- **Physical test device**: iPad Air 13" M3
- All layouts must be tested on both form factors

## File structure
dislexia/
├── dislexiaApp.swift
├── Navigation/AppRouter.swift
├── Models/
├── Persistence/LibraryStore.swift
├── Engines/
│   ├── SpanishSyllabifier.swift
│   ├── OCREngine.swift
│   ├── TTSEngine.swift
│   └── AIEngine.swift
├── Views/
│   ├── LibraryView.swift
│   ├── CameraView.swift
│   ├── ReaderView.swift
│   ├── SettingsView.swift
│   ├── ComprehensionView.swift
│   └── Components/
└── Resources/

## Reference document
Full technical spec: `DislexIA_Dev_Spec.md` (project root).
Read it completely before writing any code.

## Creative liberty
You have full creative freedom to improve on the spec when you see a better approach.
- If a different architecture, animation, layout, or interaction pattern would result in a
  superior experience, implement it and briefly note what you changed and why
- The spec is a strong starting point, not a ceiling — exceed it where you can
- Prioritize: feel > spec fidelity. A more elegant solution always wins
- The only hard constraints are the Swift 6 rules, accessibility requirements, and
  Apple-frameworks-only (no third-party packages)

## What NOT to do
- Do NOT use UIKit unless wrapping camera (UIImagePickerController) — everything else SwiftUI
- Do NOT add any Swift Package dependencies
- Do NOT use @AppStorage for complex state — use AppPreferences singleton
- Do NOT generate or modify .pbxproj manually — ask user to add files in Xcode
- Do NOT use deprecated APIs (NavigationView, ObservableObject, etc.)
- Do NOT skip #Preview macros
- Do NOT leave TODO comments — implement or leave a fatalError with a clear message
