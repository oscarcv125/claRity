import Foundation
import NaturalLanguage

/// Idioma del documento que se está leyendo (no del UI de la app).
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

    /// Código corto para la insignia del selector de idioma.
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

    /// Voces BCP-47 en orden de preferencia para AVSpeechSynthesisVoice.
    var voiceCodes: [String] {
        switch self {
        case .spanish: return ["es-MX", "es-ES", "es"]
        case .english: return ["en-US", "en-GB", "en"]
        }
    }

    /// Sílabas según el idioma (RAE para español, heurística para inglés).
    func syllabify(_ word: String) -> [String] {
        switch self {
        case .spanish: return SpanishSyllabifier.syllabify(word)
        case .english: return EnglishSyllabifier.syllabify(word)
        }
    }

    /// Detecta el idioma dominante de un texto (limitado a es/en).
    /// Español por defecto si no se puede determinar.
    static func detect(from text: String) -> ReadingLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.spanish, .english]
        recognizer.processString(String(text.prefix(500)))
        guard let dominant = recognizer.dominantLanguage else { return .spanish }
        return dominant == .english ? .english : .spanish
    }
}

/// Qué hacer con definiciones y preguntas cuando el documento está en inglés.
enum EnglishDefinitionMode: String, CaseIterable, Identifiable {
    /// Explica en español (con la traducción) — para entender el texto.
    case translate = "translate"
    /// Todo en inglés sencillo — para practicar el idioma.
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
