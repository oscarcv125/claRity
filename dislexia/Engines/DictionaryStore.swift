import Foundation
import NaturalLanguage

/// Entrada de diccionario offline usada para "anclar" (ground) las
/// definiciones de la IA y evitar alucinaciones.
struct DictionaryEntry: Decodable, Sendable {
    let definitions: [String]
    let example: String?
}

/// Diccionarios offline empaquetados en la app (RAG ligero), uno por idioma.
///
/// La recuperación es por búsqueda exacta de lema — no se necesitan
/// embeddings para palabras sueltas:
/// 1. Búsqueda directa de la palabra en minúsculas.
/// 2. Lematización con NLTagger ("corrían" → "correr", "running" → "run").
/// 3. Heurística de plurales ("semillas" → "semilla", "boats" → "boat").
///
/// Para ampliar la cobertura, reemplaza los JSON con un extracto filtrado
/// de Wiktionary (kaikki.org, licencia CC BY-SA).
final class DictionaryStore: Sendable {
    static let shared = DictionaryStore()

    private let spanishEntries: [String: DictionaryEntry]
    private let englishEntries: [String: DictionaryEntry]

    private init() {
        spanishEntries = Self.load(resource: "seed_dictionary")
        englishEntries = Self.load(resource: "seed_dictionary_en")
    }

    private static func load(resource: String) -> [String: DictionaryEntry] {
        guard
            let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: DictionaryEntry].self, from: data)
        else { return [:] }
        return decoded
    }

    /// Número de palabras disponibles (útil para depurar la carga del recurso).
    func wordCount(for language: ReadingLanguage) -> Int {
        entries(for: language).count
    }

    private func entries(for language: ReadingLanguage) -> [String: DictionaryEntry] {
        switch language {
        case .spanish: return spanishEntries
        case .english: return englishEntries
        }
    }

    /// Busca una palabra; devuelve `nil` si no hay entrada (la IA actúa sola).
    func lookup(_ word: String, language: ReadingLanguage = .spanish) -> DictionaryEntry? {
        let dict = entries(for: language)
        let clean = word
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        guard !clean.isEmpty else { return nil }

        // 1. Coincidencia exacta
        if let hit = dict[clean] { return hit }

        // 2. Lema (maneja conjugaciones y plurales irregulares)
        if let lemma = lemmatize(clean, language: language), let hit = dict[lemma] {
            return hit
        }

        // 3. Heurística simple de plurales
        if language == .english, clean.hasSuffix("ies"),
           let hit = dict[String(clean.dropLast(3)) + "y"] { return hit }
        if clean.hasSuffix("es"), let hit = dict[String(clean.dropLast(2))] { return hit }
        if clean.hasSuffix("s"), let hit = dict[String(clean.dropLast())] { return hit }

        return nil
    }

    private func lemmatize(_ word: String, language: ReadingLanguage) -> String? {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        tagger.setLanguage(language.nlLanguage, range: word.startIndex..<word.endIndex)
        let (tag, _) = tagger.tag(at: word.startIndex, unit: .word, scheme: .lemma)
        guard let lemma = tag?.rawValue.lowercased(), lemma != word else { return nil }
        return lemma
    }
}
