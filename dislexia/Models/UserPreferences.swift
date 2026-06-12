import SwiftUI

struct UserPreferences {
    static let fontSizeKey          = "pref_fontSize"
    static let letterSpacingKey     = "pref_letterSpacing"
    static let lineSpacingKey       = "pref_lineSpacing"
    static let readingSpeedKey      = "pref_readingSpeed"
    static let backgroundColorKey   = "pref_backgroundColor"
    static let useOpenDyslexicKey   = "pref_useOpenDyslexic"
    static let englishDefinitionModeKey = "pref_englishDefinitionMode"
    static let usePersonalVoiceKey      = "pref_usePersonalVoice"

    static let defaultFontSize: Double      = 22
    static let defaultLetterSpacing: Double = 2
    static let defaultLineSpacing: Double   = 12
    static let defaultReadingSpeed: Double  = 0.42
    static let defaultBackgroundColor       = BackgroundOption.cream
    static let defaultUseOpenDyslexic: Bool = true
    static let defaultEnglishDefinitionMode = EnglishDefinitionMode.translate
    static let defaultUsePersonalVoice: Bool = false
}

enum BackgroundOption: String, CaseIterable, Identifiable {
    case white      = "Blanco"
    case cream      = "Crema"
    case lightBlue  = "Azul Pálido"
    case lightGreen = "Verde Suave"
    case dark       = "Oscuro"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white:      return Color(hex: "#FFFFFF")
        case .cream:      return Color(hex: "#FFFDF0")
        case .lightBlue:  return Color(hex: "#EEF4FF")
        case .lightGreen: return Color(hex: "#F0FFF4")
        case .dark:       return Color(hex: "#1A1A1A")
        }
    }

    var textColor: Color {
        switch self {
        case .dark:
            return Color(hex: "#F5F5F7")
        default:
            return Color(hex: "#1C1917")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let int = UInt64(hex, radix: 16) ?? 0
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
