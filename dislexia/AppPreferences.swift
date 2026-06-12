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

    var fontName: String {
        if useOpenDyslexic, UIFont(name: "OpenDyslexic", size: 17) != nil {
            return "OpenDyslexic"
        }
        return UIFont.systemFont(ofSize: 17).fontName
    }

    private init() {
        let ud = UserDefaults.standard
        fontSize      = ud.double(forKey: UserPreferences.fontSizeKey).nonZero ?? UserPreferences.defaultFontSize
        letterSpacing = ud.double(forKey: UserPreferences.letterSpacingKey).nonZero ?? UserPreferences.defaultLetterSpacing
        lineSpacing   = ud.double(forKey: UserPreferences.lineSpacingKey).nonZero ?? UserPreferences.defaultLineSpacing
        readingSpeed  = ud.double(forKey: UserPreferences.readingSpeedKey).nonZero ?? UserPreferences.defaultReadingSpeed
        useOpenDyslexic = ud.object(forKey: UserPreferences.useOpenDyslexicKey) as? Bool ?? UserPreferences.defaultUseOpenDyslexic
        let colorRaw  = ud.string(forKey: UserPreferences.backgroundColorKey) ?? ""
        backgroundColor = BackgroundOption(rawValue: colorRaw) ?? UserPreferences.defaultBackgroundColor
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
