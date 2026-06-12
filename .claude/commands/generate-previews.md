---
description: Generate comprehensive #Preview macros for all views
---
For every SwiftUI view in the Views/ directory that is missing a #Preview:

1. Generate a realistic #Preview with sample data
2. Include dark mode variant: .preferredColorScheme(.dark)
3. Include large text variant: .dynamicTypeSize(.accessibility3)
4. Include iPad variant where layout differs
5. Use PreviewProvider-style naming: "Light", "Dark", "Large Text"

Use the preloaded library content from PreloadedLibrary.swift for sample data.
