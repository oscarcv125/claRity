---
description: Audit and fix accessibility issues in a SwiftUI file
---
Audit the specified SwiftUI file for accessibility issues:
1. Every interactive element has accessibilityLabel
2. Compound views use .accessibilityElement(children: .combine)
3. All tap targets are at least 44×44pt
4. Color is never the only indicator of state
5. Animations respect @Environment(\.accessibilityReduceMotion)
6. VoiceOver navigation order is logical

Fix all issues found. Show a before/after diff.
