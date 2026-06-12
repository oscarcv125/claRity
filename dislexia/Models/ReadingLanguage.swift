import Foundation
import NaturalLanguage

// docs
enum ReadingLanguage: String, CaseIterable, Identifiable, Sendable {
    case spanish = "es"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    // docs
    var shortCode: String {
        switch self {
        case .spanish: return "ES"
        case .english: return "EN"
        }
    }

    var nlLanguage: NLLanguage {
        switch self {
        case .spanish: return .spanish
        case .english: return .english
        }
    }

    // docs
    var voiceCodes: [String] {
        switch self {
        case .spanish: return ["es-MX", "es-ES", "es"]
        case .english: return ["en-US", "en-GB", "en"]
        }
    }

    // docs
    func syllabify(_ word: String) -> [String] {
        switch self {
        case .spanish: return SpanishSyllabifier.syllabify(word)
        case .english: return EnglishSyllabifier.syllabify(word)
        }
    }

    // docs
    static func detect(from text: String) -> ReadingLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.spanish, .english]
        recognizer.processString(String(text.prefix(500)))
        guard let dominant = recognizer.dominantLanguage else { return .spanish }
        return dominant == .english ? .english : .spanish
    }
}

// docs
enum EnglishDefinitionMode: String, CaseIterable, Identifiable {
    // docs
    case translate = "translate"
    // pendiente
    case immersion = "immersion"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .translate: return "Traducir al español"
        case .immersion: return "Practicar en inglés"
        }
    }

    var subtitle: String {
        switch self {
        case .translate: return "Definiciones y preguntas en español, con la traducción de cada palabra"
        case .immersion: return "Definiciones y preguntas en inglés sencillo, para aprender el idioma"
        }
    }

    var icon: String {
        switch self {
        case .translate: return "arrow.left.arrow.right"
        case .immersion: return "graduationcap.fill"
        }
    }
}
