import Foundation
import NaturalLanguage

// docs
enum SpanishSyllabifier {


    static func syllabify(_ word: String) -> [String] {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return [] }

        let cleaned = lower.filter {
            $0.isLetter || "áéíóúüñ".contains($0)
        }
        guard !cleaned.isEmpty else { return [word] }

        let chars = Array(cleaned)
        var syllables: [String] = []
        var i = 0

        while i < chars.count {
            guard let nucleusEnd = findNucleus(in: chars, from: i) else {
                if !syllables.isEmpty {
                    syllables[syllables.count - 1] += String(chars[i...])
                } else {
                    syllables.append(String(chars[i...]))
                }
                break
            }

            let onsetStart = i
            var onsetEnd = i
            while onsetEnd < nucleusEnd && !isVowel(chars[onsetEnd]) {
                onsetEnd += 1
            }

            let nucleus = nucleusEnd

            var codaEnd = nucleus + 1
            if codaEnd < chars.count && !isVowel(chars[codaEnd]) {
                if let nextVowel = findNextVowel(in: chars, from: codaEnd) {
                    let consonantsBetween = Array(chars[codaEnd..<nextVowel])
                    let splitPoint = splitConsonants(consonantsBetween)
                    codaEnd = codaEnd + splitPoint
                } else {
                    codaEnd = chars.count
                }
            }

            let syllable = String(chars[onsetStart..<codaEnd])
            syllables.append(syllable)
            i = codaEnd
        }

        return syllables.isEmpty ? [word] : syllables
    }


    static func isVowel(_ c: Character) -> Bool {
        "aeiouáéíóúü".contains(c)
    }

    static func isStrongVowel(_ c: Character) -> Bool {
        "aeoáéó".contains(c)
    }

    static func isWeakVowel(_ c: Character) -> Bool {
        "iuíú".contains(c)
    }


    private static func findNucleus(in chars: [Character], from start: Int) -> Int? {
        guard let firstVowelIdx = (start..<chars.count).first(where: { isVowel(chars[$0]) })
        else { return nil }

        var nucleusEnd = firstVowelIdx

        if nucleusEnd + 1 < chars.count {
            let next = chars[nucleusEnd + 1]
            if isVowel(next) {
                let current = chars[nucleusEnd]
                // logica
                let bothStrong   = isStrongVowel(current) && isStrongVowel(next)
                let weakAccented = "íú".contains(current) || "íú".contains(next)

                if !bothStrong && !weakAccented {
                    nucleusEnd += 1
                    if nucleusEnd + 1 < chars.count {
                        let third = chars[nucleusEnd + 1]
                        if isWeakVowel(third) && !"íú".contains(third) {
                            nucleusEnd += 1
                        }
                    }
                }
            }
        }

        return nucleusEnd
    }


    private static func findNextVowel(in chars: [Character], from start: Int) -> Int? {
        (start..<chars.count).first(where: { isVowel(chars[$0]) })
    }

    private static func splitConsonants(_ consonants: [Character]) -> Int {
        switch consonants.count {
        case 0: return 0
        case 1: return 0
        case 2:
            let pair = String(consonants)
            let inseparable = ["bl","br","cl","cr","dr","fl","fr","gl","gr",
                               "pl","pr","tr","ch","ll","rr"]
            return inseparable.contains(pair) ? 0 : 1
        default:
            // 3+ consonantes: el grupo inseparable final (p. ej. "tr" en "nstr")
            // pertenece a la siguiente sílaba — ins-truc-ción, no inst-ruc-ción
            let last2 = String(consonants.suffix(2))
            let inseparable2 = ["bl","br","cl","cr","dr","fl","fr","gl","gr","pl","pr","tr"]
            return inseparable2.contains(last2) ? consonants.count - 2 : consonants.count - 1
        }
    }
}


extension SpanishSyllabifier {

    static func tokenize(_ text: String) -> (
        wordRanges: [Range<String.Index>],
        syllables: [[String]]
    ) {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.spanish)

        var ranges: [Range<String.Index>] = []
        var allSyllables: [[String]] = []

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range])
            ranges.append(range)
            allSyllables.append(syllabify(word))
            return true
        }

        return (ranges, allSyllables)
    }
}
