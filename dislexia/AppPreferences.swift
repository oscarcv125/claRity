import SwiftUI

@Observable
@MainActor
final class AppPreferences {
    static let shared = AppPreferences()

    var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: UserPreferences.fontSizeKey) }
    }
    var letterSpacing: Double {
        didSet { UserDefaults.standard.set(letterSpacing, forKey: UserPreferences.letterSpacingKey) }
    }
    var lineSpacing: Double {
        didSet { UserDefaults.standard.set(lineSpacing, forKey: UserPreferences.lineSpacingKey) }
    }
    var readingSpeed: Double {
        didSet { UserDefaults.standard.set(readingSpeed, forKey: UserPreferences.readingSpeedKey) }
    }
    var backgroundColor: BackgroundOption {
        didSet { UserDefaults.standard.set(backgroundColor.rawValue, forKey: UserPreferences.backgroundColorKey) }
    }
    var useOpenDyslexic: Bool {
        didSet { UserDefaults.standard.set(useOpenDyslexic, forKey: UserPreferences.useOpenDyslexicKey) }
    }
    var englishDefinitionMode: EnglishDefinitionMode {
        didSet { UserDefaults.standard.set(englishDefinitionMode.rawValue, forKey: UserPreferences.englishDefinitionModeKey) }
    }
    var usePersonalVoice: Bool {
        didSet { UserDefaults.standard.set(usePersonalVoice, forKey: UserPreferences.usePersonalVoiceKey) }
    }

    var fontName: String {
        if useOpenDyslexic, UIFont(name: "OpenDyslexic", size: 17) != nil {
            return "OpenDyslexic"
        }
        return UIFont.systemFont(ofSize: 17).fontName
    }

    private init() {
        let ud = UserDefaults.standard
        fontSize      = ud.object(forKey: UserPreferences.fontSizeKey) as? Double ?? UserPreferences.defaultFontSize
        letterSpacing = ud.object(forKey: UserPreferences.letterSpacingKey) as? Double ?? UserPreferences.defaultLetterSpacing
        lineSpacing   = ud.object(forKey: UserPreferences.lineSpacingKey) as? Double ?? UserPreferences.defaultLineSpacing
        readingSpeed  = ud.object(forKey: UserPreferences.readingSpeedKey) as? Double ?? UserPreferences.defaultReadingSpeed
        useOpenDyslexic = ud.object(forKey: UserPreferences.useOpenDyslexicKey) as? Bool ?? UserPreferences.defaultUseOpenDyslexic
        let colorRaw  = ud.string(forKey: UserPreferences.backgroundColorKey) ?? ""
        backgroundColor = BackgroundOption(rawValue: colorRaw) ?? UserPreferences.defaultBackgroundColor
        let modeRaw   = ud.string(forKey: UserPreferences.englishDefinitionModeKey) ?? ""
        englishDefinitionMode = EnglishDefinitionMode(rawValue: modeRaw) ?? UserPreferences.defaultEnglishDefinitionMode
        usePersonalVoice = ud.object(forKey: UserPreferences.usePersonalVoiceKey) as? Bool ?? UserPreferences.defaultUsePersonalVoice
    }
}
