---
description: Apply iOS 26 Liquid Glass polish to a SwiftUI view
---
Take the specified SwiftUI view and apply full iOS 26 Liquid Glass polish:

1. Replace plain backgrounds with .glassEffect() where appropriate
2. Wrap related glass elements in GlassEffectContainer
3. Add spring animations to state transitions
4. Add morphing transitions with .glassEffectID() where views transform
5. Ensure .ultraThinMaterial or pastel backgrounds behind glass
6. Add haptic feedback to interactive elements
7. Smooth scroll physics with .scrollTargetBehavior
8. Add subtle shadow hierarchy to create depth

Do NOT over-glass. Follow the rule: glass for controls, solid for content.
