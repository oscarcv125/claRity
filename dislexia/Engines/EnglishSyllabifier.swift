import Foundation

/// Silabificación heurística del inglés (agrupación de núcleos vocálicos).
/// No es perfecta — el inglés no tiene reglas regulares — pero funciona bien
/// para palabras escolares ("wa-ter", "but-ter-fly", "light-house").
/// Cuando hay Apple Intelligence, `AIEngine.syllabify` la refina.
enum EnglishSyllabifier {

    static func syllabify(_ word: String) -> [String] {
        let cleaned = word.lowercased().filter { $0.isLetter }
        guard !cleaned.isEmpty else { return [word] }

        let chars = Array(cleaned)
        let vowels = Set("aeiouy")

        // 1. Encuentra los grupos vocálicos (núcleos).
        var nuclei: [Range<Int>] = []
        var i = 0
        while i < chars.count {
            if vowels.contains(chars[i]) {
                var j = i
                while j < chars.count, vowels.contains(chars[j]) { j += 1 }
                nuclei.append(i..<j)
                i = j
            } else {
                i += 1
            }
        }

        // 2. "e" muda final: no forma sílaba propia (ta-ke → take).
        if nuclei.count > 1,
           let last = nuclei.last,
           last.count == 1,
           chars[last.lowerBound] == "e",
           last.upperBound == chars.count {
            nuclei.removeLast()
        }

        guard nuclei.count > 1 else { return [cleaned] }

        // 3. Reparte las consonantes entre núcleos:
        //    0 consonantes → corte justo antes del siguiente núcleo
        //    1 consonante  → la consonante abre la siguiente sílaba (wa-ter)
        //    2+            → se divide después de la primera (but-ter)
        var cuts: [Int] = []
        for k in 0..<(nuclei.count - 1) {
            let gapStart = nuclei[k].upperBound
            let gapEnd = nuclei[k + 1].lowerBound
            switch gapEnd - gapStart {
            case 0:  cuts.append(gapEnd)
            case 1:  cuts.append(gapStart)
            default: cuts.append(gapStart + 1)
            }
        }

        var result: [String] = []
        var start = 0
        for cut in cuts where cut > start {
            result.append(String(chars[start..<cut]))
            start = cut
        }
        result.append(String(chars[start...]))
        return result.filter { !$0.isEmpty }
    }
}
