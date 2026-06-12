---
description: Review a Swift file for Swift 6 concurrency safety
---
Review the specified Swift file for Swift 6 compliance:

1. All async calls on correct actor (@MainActor UI updates)
2. No data races — Sendable conformance where needed
3. No deprecated concurrency patterns (DispatchQueue for UI, NotificationCenter without async)
4. Actors used correctly for shared mutable state
5. No force unwraps
6. No retain cycles (weak self in closures that capture self)
7. @Observable instead of ObservableObject

Report each issue with line number and fix. Apply all fixes.
