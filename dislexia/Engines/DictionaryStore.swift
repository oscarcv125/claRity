import Foundation
import NaturalLanguage

// docs
struct DictionaryEntry: Decodable, Sendable {
    let definitions: [String]
    let example: String?
}

// docs
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

    // docs
    func wordCount(for language: ReadingLanguage) -> Int {
        entries(for: language).count
    }

    private func entries(for language: ReadingLanguage) -> [String: DictionaryEntry] {
        switch language {
        case .spanish: return spanishEntries
        case .english: return englishEntries
        }
    }

    // docs
    func lookup(_ word: String, language: ReadingLanguage = .spanish) -> DictionaryEntry? {
        let dict = entries(for: language)
        let clean = word
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        guard !clean.isEmpty else { return nil }

        if let hit = dict[clean] { return hit }

        // logica
        if let lemma = lemmatize(clean, language: language), let hit = dict[lemma] {
            return hit
        }

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
