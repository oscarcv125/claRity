# DislexIA — Full Developer Specification
> **Audience:** Claude Code / developer agent. This document is self-contained and sufficient to build the entire project from scratch.  
> **Target:** iOS 18+, iPhone & iPad, Swift 6, SwiftUI, Xcode 16+  
> **Constraint:** 100% on-device. No network calls. No backend. No third-party SDKs beyond OpenDyslexic font.

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [File & Folder Structure](#2-file--folder-structure)
3. [Data Models](#3-data-models)
4. [Persistence Layer](#4-persistence-layer)
5. [Spanish Syllabifier — Full Algorithm](#5-spanish-syllabifier--full-algorithm)
6. [Vision OCR Module](#6-vision-ocr-module)
7. [TTS + Syllable Sync Engine](#7-tts--syllable-sync-engine)
8. [Foundation Models (On-Device AI)](#8-foundation-models-on-device-ai)
9. [User Preferences](#9-user-preferences)
10. [SwiftUI Views — Full Spec](#10-swiftui-views--full-spec)
11. [Navigation & App Shell](#11-navigation--app-shell)
12. [Accessibility Requirements](#12-accessibility-requirements)
13. [Assets & Fonts](#13-assets--fonts)
14. [Info.plist & Entitlements](#14-infoplist--entitlements)
15. [Pre-loaded Library Content](#15-pre-loaded-library-content)
16. [Edge Cases & Error Handling](#16-edge-cases--error-handling)
17. [Build & Test Checklist](#17-build--test-checklist)

---

## 1. Project Setup

### Xcode Project Settings

```
Product Name:        DislexIA
Bundle Identifier:   com.tec.dislex-ia
Team:                (personal / student team)
Deployment Target:   iOS 18.0
Interface:           SwiftUI
Language:            Swift
Include Tests:       Yes (Unit + UI)
```

### Swift Package Dependencies

None. All functionality uses Apple frameworks only.

### Frameworks to link (all built-in, just import)

```swift
import SwiftUI
import Vision                  // OCR
import NaturalLanguage         // tokenization
import AVFoundation            // TTS
import FoundationModels        // on-device LLM (iOS 18)
import PhotosUI                // photo picker fallback
import Combine                 // reactive state
```

---

## 2. File & Folder Structure

```
DislexIA/
├── DislexIAApp.swift               // @main entry point
├── Navigation/
│   └── AppRouter.swift             // NavigationStack path enum
├── Models/
│   ├── LibraryItem.swift           // text content model
│   ├── ReadingSession.swift        // active reading state
│   ├── ComprehensionQuestion.swift // Q&A model
│   └── UserPreferences.swift       // reading config
├── Persistence/
│   └── LibraryStore.swift          // SwiftData store
├── Engines/
│   ├── SpanishSyllabifier.swift    // syllabification algorithm
│   ├── OCREngine.swift             // Vision wrapper
│   ├── TTSEngine.swift             // AVSpeechSynthesizer wrapper
│   └── AIEngine.swift              // FoundationModels wrapper
├── Views/
│   ├── LibraryView.swift           // Screen 1
│   ├── CameraView.swift            // Screen 2
│   ├── ReaderView.swift            // Screen 3 (main)
│   ├── SettingsView.swift          // Screen 4
│   ├── ComprehensionView.swift     // Screen 5
│   └── Components/
│       ├── SyllableText.swift      // highlighted AttributedString view
│       ├── WordDefinitionCard.swift
│       ├── ReadingControlBar.swift
│       └── BackgroundColorPicker.swift
├── Resources/
│   ├── OpenDyslexic-Regular.otf
│   ├── OpenDyslexic-Bold.otf
│   └── LibraryContent.json         // pre-loaded texts
└── DislexIA.xcdatamodeld           // (not used — SwiftData instead)
```

---

## 3. Data Models

### 3.1 LibraryItem.swift

```swift
import Foundation
import SwiftData

enum DifficultyLevel: String, Codable, CaseIterable {
    case basic      = "Básico"
    case intermediate = "Intermedio"
    case advanced   = "Avanzado"
}

enum TextSource: String, Codable {
    case preloaded  // bundled in app
    case camera     // captured via OCR
    case manual     // typed by user
}

@Model
final class LibraryItem {
    var id: UUID
    var title: String
    var body: String                  // full text content
    var level: DifficultyLevel
    var source: TextSource
    var createdAt: Date
    var lastReadAt: Date?
    var readCount: Int

    init(
        id: UUID = .init(),
        title: String,
        body: String,
        level: DifficultyLevel,
        source: TextSource = .preloaded,
        createdAt: Date = .now,
        lastReadAt: Date? = nil,
        readCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.level = level
        self.source = source
        self.createdAt = createdAt
        self.lastReadAt = lastReadAt
        self.readCount = readCount
    }
}
```

### 3.2 ReadingSession.swift

```swift
import Foundation
import Combine

/// Ephemeral — lives only while ReaderView is active. Not persisted.
@Observable
final class ReadingSession {
    // Content
    var fullText: String = ""
    var syllables: [[String]] = []     // syllables[wordIndex] = ["a","pren","der"]
    var wordRanges: [Range<String.Index>] = []

    // Playback state
    var isPlaying: Bool = false
    var currentWordIndex: Int = -1
    var currentSyllableIndex: Int = -1

    // Highlight — the range in fullText currently highlighted
    var highlightRange: Range<String.Index>? = nil

    // AI state
    var simplifiedText: String? = nil
    var isSimplifying: Bool = false
    var selectedWordDefinition: String? = nil
    var isDefining: Bool = false

    // Comprehension
    var comprehensionQuestions: [ComprehensionQuestion] = []
    var isGeneratingQuestions: Bool = false
    var comprehensionComplete: Bool = false
}
```

### 3.3 ComprehensionQuestion.swift

```swift
import Foundation

struct ComprehensionQuestion: Identifiable {
    let id = UUID()
    let question: String
    var answer: Bool? = nil          // nil = unanswered, true = Sí, false = No
}
```

### 3.4 UserPreferences.swift

```swift
import SwiftUI

/// Stored in UserDefaults via @AppStorage wrappers in SettingsView.
/// This struct is just a namespace for keys and defaults.
struct UserPreferences {
    static let fontSizeKey          = "pref_fontSize"
    static let letterSpacingKey     = "pref_letterSpacing"
    static let lineSpacingKey       = "pref_lineSpacing"
    static let readingSpeedKey      = "pref_readingSpeed"
    static let backgroundColorKey   = "pref_backgroundColor"
    static let useOpenDyslexicKey   = "pref_useOpenDyslexic"

    static let defaultFontSize: Double      = 22
    static let defaultLetterSpacing: Double = 2
    static let defaultLineSpacing: Double   = 12
    static let defaultReadingSpeed: Double  = 0.42   // AVSpeechUtterance rate
    static let defaultBackgroundColor       = BackgroundOption.cream
    static let defaultUseOpenDyslexic: Bool = true
}

enum BackgroundOption: String, CaseIterable, Identifiable {
    case white      = "Blanco"
    case cream      = "Crema"
    case lightBlue  = "Azul Pálido"
    case lightGreen = "Verde Suave"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white:      return Color(hex: "#FFFFFF")
        case .cream:      return Color(hex: "#FFFDF0")
        case .lightBlue:  return Color(hex: "#EEF4FF")
        case .lightGreen: return Color(hex: "#F0FFF4")
        }
    }
}

// MARK: - Color hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let int = UInt64(hex, radix: 16) ?? 0
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

---

## 4. Persistence Layer

### 4.1 LibraryStore.swift

Uses **SwiftData** (iOS 17+). Pre-loaded texts are seeded on first launch.

```swift
import SwiftData
import Foundation

@MainActor
final class LibraryStore {
    static let shared = LibraryStore()

    let container: ModelContainer

    private init() {
        let schema = Schema([LibraryItem.self])
        let config = ModelConfiguration("DislexIA", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }

    /// Call once at app launch. Seeds preloaded content if DB is empty.
    func seedIfNeeded() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<LibraryItem>())) ?? 0
        guard count == 0 else { return }

        for item in PreloadedLibrary.items {
            context.insert(item)
        }
        try? context.save()
    }

    func save(title: String, body: String, level: DifficultyLevel, source: TextSource) {
        let item = LibraryItem(title: title, body: body, level: level, source: source)
        container.mainContext.insert(item)
        try? container.mainContext.save()
    }

    func markRead(_ item: LibraryItem) {
        item.lastReadAt = .now
        item.readCount += 1
        try? container.mainContext.save()
    }

    func delete(_ item: LibraryItem) {
        container.mainContext.delete(item)
        try? container.mainContext.save()
    }
}
```

---

## 5. Spanish Syllabifier — Full Algorithm

This is the core proprietary logic. Implement exactly as specified.

### 5.1 SpanishSyllabifier.swift

```swift
import Foundation

/// Full Spanish syllabification following RAE rules.
/// Returns an array of syllables for a given word.
/// Example: syllabify("aprender") → ["a", "pren", "der"]
enum SpanishSyllabifier {

    // MARK: - Public API

    static func syllabify(_ word: String) -> [String] {
        let lower = word.lowercased()
        guard !lower.isEmpty else { return [] }

        // Strip punctuation attached to word boundaries
        let cleaned = lower.filter { $0.isLetter || $0 == "á" || $0 == "é"
                                        || $0 == "í" || $0 == "ó" || $0 == "ú"
                                        || $0 == "ü" || $0 == "ñ" }
        guard !cleaned.isEmpty else { return [word] }

        let chars = Array(cleaned)
        var syllables: [String] = []
        var i = 0

        while i < chars.count {
            // Find nucleus (vowel or diphthong/triphthong)
            guard let nucleusEnd = findNucleus(in: chars, from: i) else {
                // No more vowels — attach remaining consonants to last syllable
                if !syllables.isEmpty {
                    syllables[syllables.count - 1] += String(chars[i...])
                } else {
                    syllables.append(String(chars[i...]))
                }
                break
            }

            // Collect onset consonants before nucleus
            let onsetStart = i
            var onsetEnd = i
            while onsetEnd < nucleusEnd && !isVowel(chars[onsetEnd]) {
                onsetEnd += 1
            }

            // Nucleus end
            let nucleus = nucleusEnd

            // Find coda: consonants after nucleus, before next vowel/nucleus
            var codaEnd = nucleus + 1
            if codaEnd < chars.count && !isVowel(chars[codaEnd]) {
                let lookahead = findNextVowel(in: chars, from: codaEnd)
                if let nextVowel = lookahead {
                    // Apply onset maximization:
                    // Keep consonants on next syllable if they form a valid onset cluster
                    let consonantsBetween = Array(chars[codaEnd..<nextVowel])
                    let splitPoint = splitConsonants(consonantsBetween)
                    codaEnd = codaEnd + splitPoint
                } else {
                    codaEnd = chars.count  // rest goes to coda of last syllable
                }
            }

            let syllable = String(chars[onsetStart..<codaEnd])
            syllables.append(syllable)
            i = codaEnd
        }

        // Restore original casing pattern if needed
        return syllables.isEmpty ? [word] : syllables
    }

    // MARK: - Vowel detection

    static func isVowel(_ c: Character) -> Bool {
        return "aeiouáéíóúü".contains(c)
    }

    static func isStrongVowel(_ c: Character) -> Bool {
        return "aeoáéó".contains(c)
    }

    static func isWeakVowel(_ c: Character) -> Bool {
        return "iuíú".contains(c)
    }

    // MARK: - Nucleus finder (handles diphthongs and triphthongs)

    /// Returns the index of the LAST character of the nucleus starting at `from`.
    private static func findNucleus(in chars: [Character], from start: Int) -> Int? {
        // Find first vowel
        guard let firstVowelIdx = (start..<chars.count).first(where: { isVowel(chars[$0]) })
        else { return nil }

        var nucleusEnd = firstVowelIdx

        // Check for diphthong/triphthong
        // Diphthong: strong+weak, weak+strong, weak+weak (with accent rules)
        if nucleusEnd + 1 < chars.count {
            let next = chars[nucleusEnd + 1]
            if isVowel(next) {
                let current = chars[nucleusEnd]
                // Forms a diphthong if:
                // - one is weak and unstressed, or both are weak
                // - NOT two strong vowels (hiatus)
                let bothStrong = isStrongVowel(current) && isStrongVowel(next)
                let currentAccented = "áéó".contains(current)
                let nextAccented = "áéó".contains(next)
                let weakAccented = "íú".contains(current) || "íú".contains(next)

                if !bothStrong && !currentAccented && !nextAccented && !weakAccented {
                    nucleusEnd += 1  // diphthong
                    // Check triphthong: weak + strong + weak
                    if nucleusEnd + 1 < chars.count {
                        let third = chars[nucleusEnd + 1]
                        if isWeakVowel(third) && !("íú".contains(third)) {
                            nucleusEnd += 1
                        }
                    }
                }
            }
        }

        return nucleusEnd
    }

    // MARK: - Next vowel finder

    private static func findNextVowel(in chars: [Character], from start: Int) -> Int? {
        return (start..<chars.count).first(where: { isVowel(chars[$0]) })
    }

    // MARK: - Consonant cluster splitter (onset maximization)

    /// Given consonants between two vowels, returns how many belong to the CODA
    /// (i.e. stay with the previous syllable). The rest form the onset of next.
    private static func splitConsonants(_ consonants: [Character]) -> Int {
        switch consonants.count {
        case 0:
            return 0
        case 1:
            // Single consonant always goes to next syllable as onset
            return 0
        case 2:
            let pair = String(consonants)
            // Inseparable clusters (always onset of next syllable):
            let inseparable = ["bl","br","cl","cr","dr","fl","fr","gl","gr",
                               "pl","pr","tr","ch","ll","rr"]
            if inseparable.contains(pair) {
                return 0   // both go to next syllable
            }
            // "ns", "rs", "ls", "st", "nt", "nd", "rc", "rt" etc → split 1+1
            return 1
        case 3:
            // e.g. "ntr" → n stays, "tr" goes next; "str" → s stays, "tr" goes next
            let last2 = String(consonants.suffix(2))
            let inseparable2 = ["bl","br","cl","cr","dr","fl","fr","gl","gr",
                                "pl","pr","tr"]
            if inseparable2.contains(last2) {
                return consonants.count - 2  // keep all but last 2 in coda
            }
            return consonants.count - 1
        default:
            // More than 3 consonants — keep all but last valid onset
            return consonants.count - 1
        }
    }
}

// MARK: - NLTokenizer integration

import NaturalLanguage

extension SpanishSyllabifier {

    /// Tokenizes a full text into words, returns word ranges + syllables for each.
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
```

---

## 6. Vision OCR Module

### 6.1 OCREngine.swift

```swift
import Vision
import UIKit
import Combine

@Observable
final class OCREngine {
    var extractedText: String = ""
    var isProcessing: Bool = false
    var error: String? = nil

    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.error = "No se pudo procesar la imagen."
            return
        }

        isProcessing = true
        error = nil

        let request = VNRecognizeTextRequest { [weak self] request, err in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isProcessing = false

                if let err {
                    self.error = "Error OCR: \(err.localizedDescription)"
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                // Sort by vertical position (top to bottom), then horizontal (left to right)
                let sorted = observations.sorted {
                    let y0 = $0.boundingBox.minY
                    let y1 = $1.boundingBox.minY
                    if abs(y0 - y1) > 0.05 { return y0 > y1 }  // different lines
                    return $0.boundingBox.minX < $1.boundingBox.minX
                }

                self.extractedText = sorted
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
            }
        }

        request.recognitionLanguages = ["es-MX", "es-ES", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
```

---

## 7. TTS + Syllable Sync Engine

This is the most complex module. Read carefully.

### 7.1 TTSEngine.swift

```swift
import AVFoundation
import Combine

@Observable
final class TTSEngine: NSObject {

    // MARK: - Public state (observed by ReaderView)
    var isPlaying: Bool = false
    var currentWordIndex: Int = -1
    var currentSyllableIndex: Int = -1
    var highlightRange: Range<String.Index>? = nil

    // MARK: - Private
    private let synthesizer = AVSpeechSynthesizer()
    private var wordRanges: [Range<String.Index>] = []
    private var syllables: [[String]] = []
    private var fullText: String = ""
    private var readingSpeed: Float = 0.42
    private var syllableTimers: [Timer] = []

    override init() {
        super.init()
        synthesizer.delegate = self

        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Public API

    func load(text: String, wordRanges: [Range<String.Index>], syllables: [[String]]) {
        self.fullText = text
        self.wordRanges = wordRanges
        self.syllables = syllables
        stop()
    }

    func play(speed: Double = 0.42) {
        guard !fullText.isEmpty else { return }
        readingSpeed = Float(speed)

        let utterance = AVSpeechUtterance(string: fullText)
        utterance.rate = readingSpeed
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
            ?? AVSpeechSynthesisVoice(language: "es-ES")
        utterance.postUtteranceDelay = 0.05
        utterance.preUtteranceDelay = 0

        synthesizer.speak(utterance)
        isPlaying = true
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        cancelSyllableTimers()
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPlaying = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentWordIndex = -1
        currentSyllableIndex = -1
        highlightRange = nil
        cancelSyllableTimers()
    }

    func seek(to wordIndex: Int) {
        guard wordIndex < wordRanges.count else { return }
        stop()
        // Re-speak from that word onward
        let range = wordRanges[wordIndex]
        let substring = String(fullText[range.lowerBound...])
        let utterance = AVSpeechUtterance(string: substring)
        utterance.rate = readingSpeed
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        synthesizer.speak(utterance)
        isPlaying = true
        // Offset word index so delegate math still works
        // (simplification: restart tracking from wordIndex)
        currentWordIndex = wordIndex - 1
    }

    // MARK: - Syllable animation

    /// Called by delegate when a word starts.
    /// Distributes syllable highlights evenly across word duration.
    private func animateSyllables(
        wordIndex: Int,
        wordDurationSeconds: Double
    ) {
        cancelSyllableTimers()

        let syls = syllables[safe: wordIndex] ?? []
        guard !syls.isEmpty else { return }
        let interval = wordDurationSeconds / Double(syls.count)

        for (idx, _) in syls.enumerated() {
            let delay = interval * Double(idx)
            let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.currentSyllableIndex = idx
                    self.updateHighlight(wordIndex: wordIndex, syllableIndex: idx)
                }
            }
            syllableTimers.append(timer)
        }
    }

    private func updateHighlight(wordIndex: Int, syllableIndex: Int) {
        guard wordIndex < wordRanges.count else { return }
        let wordRange = wordRanges[wordIndex]
        let word = String(fullText[wordRange])
        let syls = syllables[safe: wordIndex] ?? [word]

        // Build range of current syllable within full text
        var offset = fullText.distance(
            from: fullText.startIndex,
            to: wordRange.lowerBound
        )
        for i in 0..<syllableIndex {
            offset += syls[safe: i]?.count ?? 0
        }

        let sylLen = syls[safe: syllableIndex]?.count ?? 0
        if let start = fullText.index(
            fullText.startIndex,
            offsetBy: offset,
            limitedBy: fullText.endIndex
        ), let end = fullText.index(
            start,
            offsetBy: sylLen,
            limitedBy: fullText.endIndex
        ) {
            highlightRange = start..<end
        }
    }

    private func cancelSyllableTimers() {
        syllableTimers.forEach { $0.invalidate() }
        syllableTimers = []
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSEngine: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        guard let range = Range(characterRange, in: fullText) else { return }

        // Find which word index this range corresponds to
        let wordIdx = wordRanges.firstIndex { $0.overlaps(range) } ?? -1
        guard wordIdx >= 0 else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.currentWordIndex = wordIdx
        }

        // Estimate word duration based on rate and syllable count
        let sylCount = max(1, syllables[safe: wordIdx]?.count ?? 1)
        // Approximate: average syllable at normal rate ≈ 0.18s, scaled by rate
        let baseDuration = Double(sylCount) * 0.18 * (0.5 / Double(readingSpeed))
        animateSyllables(wordIndex: wordIdx, wordDurationSeconds: baseDuration)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.currentWordIndex = -1
            self.highlightRange = nil
            self.cancelSyllableTimers()
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        isPlaying = false
        cancelSyllableTimers()
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        isPlaying = true
    }
}

// MARK: - Safe array subscript helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

---

## 8. Foundation Models (On-Device AI)

### 8.1 AIEngine.swift

> **Note:** `FoundationModels` API in iOS 18. Use `SystemLanguageModel.default` and `LanguageModelSession`. Handle `LanguageModelSession.GenerationError` for unavailability (simulator, older devices).

```swift
import FoundationModels

@Observable
final class AIEngine {

    enum AIError: LocalizedError {
        case modelUnavailable
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "El modelo de IA no está disponible en este dispositivo."
            case .generationFailed(let msg):
                return "Error al generar respuesta: \(msg)"
            }
        }
    }

    // MARK: - Simplify text

    func simplify(text: String) async throws -> String {
        let session = try makeSession()
        let prompt = """
        Simplifica el siguiente texto para un lector de nivel primaria (6-10 años).
        Usa oraciones muy cortas. Palabras comunes. Máximo 4 oraciones.
        No uses palabras difíciles. Responde SOLO con el texto simplificado, sin explicaciones.

        Texto original:
        \(text)
        """
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Define word

    func define(word: String, context: String) async throws -> String {
        let session = try makeSession()
        let prompt = """
        Define la palabra "\(word)" de forma simple, como si le explicaras a un niño de 10 años.
        Contexto donde aparece: "\(context)"
        Responde con: 1 definición corta + 1 ejemplo de uso en una oración.
        Máximo 2 oraciones en total. Solo la definición, sin encabezados.
        """
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Comprehension questions

    func generateQuestions(for text: String) async throws -> [String] {
        let session = try makeSession()
        let prompt = """
        El usuario leyó este texto:
        \(text.prefix(800))

        Genera exactamente 3 preguntas de comprensión lectora.
        Cada pregunta debe responderse con Sí o No.
        Las preguntas deben ser simples, para un niño de primaria.
        Responde ÚNICAMENTE con las 3 preguntas, una por línea, sin numeración ni viñetas.
        """
        let response = try await session.respond(to: prompt)
        let lines = response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return Array(lines.prefix(3))
    }

    // MARK: - Summary

    func summarize(text: String) async throws -> String {
        let session = try makeSession()
        let prompt = """
        Resume el siguiente texto en exactamente 2 oraciones simples.
        Para un lector de primaria. Sin introducción, solo el resumen.

        Texto:
        \(text.prefix(1000))
        """
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Session factory

    private func makeSession() throws -> LanguageModelSession {
        guard LanguageModelSession.isSupported else {
            throw AIError.modelUnavailable
        }
        return LanguageModelSession(model: .default)
    }
}
```

---

## 9. User Preferences

### 9.1 AppPreferences.swift (Observable wrapper over UserDefaults)

```swift
import SwiftUI
import Combine

@Observable
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
        useOpenDyslexic ? "OpenDyslexic" : UIFont.systemFont(ofSize: 17).fontName
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
```

---

## 10. SwiftUI Views — Full Spec

### 10.1 LibraryView.swift

```swift
import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryItem.lastReadAt, order: .reverse) private var items: [LibraryItem]
    @State private var selectedLevel: DifficultyLevel? = nil
    @State private var showCamera = false
    @State private var showManualEntry = false
    @State private var selectedItem: LibraryItem? = nil

    private var filteredItems: [LibraryItem] {
        guard let level = selectedLevel else { return items }
        return items.filter { $0.level == level }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Level filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(label: "Todos", selected: selectedLevel == nil) {
                            selectedLevel = nil
                        }
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            FilterPill(label: level.rawValue, selected: selectedLevel == level) {
                                selectedLevel = (selectedLevel == level) ? nil : level
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // Library list
                List {
                    // Recent reads section
                    let recent = items.filter { $0.lastReadAt != nil }.prefix(3)
                    if !recent.isEmpty && selectedLevel == nil {
                        Section("Leídos recientemente") {
                            ForEach(Array(recent)) { item in
                                LibraryRow(item: item)
                                    .onTapGesture { selectedItem = item }
                            }
                        }
                    }

                    // Main content grouped by level
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        let levelItems = filteredItems.filter { $0.level == level }
                        if !levelItems.isEmpty {
                            Section(level.rawValue) {
                                ForEach(levelItems) { item in
                                    LibraryRow(item: item)
                                        .onTapGesture { selectedItem = item }
                                }
                                .onDelete { indexSet in
                                    for i in indexSet {
                                        LibraryStore.shared.delete(levelItems[i])
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("DislexIA")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showManualEntry = true
                    } label: {
                        Label("Escribir", systemImage: "pencil")
                    }
                    Spacer()
                    Button {
                        showCamera = true
                    } label: {
                        Label("Cámara", systemImage: "camera.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Capturar texto con cámara")
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { capturedText in
                    navigateToReader(text: capturedText, source: .camera)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView { title, text, level in
                    LibraryStore.shared.save(title: title, body: text, level: level, source: .manual)
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ReaderView(item: item)
            }
        }
    }

    private func navigateToReader(text: String, source: TextSource) {
        let item = LibraryItem(
            title: "Texto capturado \(Date().formatted(.dateTime.day().month()))",
            body: text,
            level: .basic,
            source: source
        )
        LibraryStore.shared.container.mainContext.insert(item)
        selectedItem = item
    }
}

struct FilterPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct LibraryRow: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
            Text(item.body.prefix(80) + "…")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.level.rawValue).")
    }
}
```

### 10.2 CameraView.swift

```swift
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onTextExtracted = { text in
            onCapture(text)
            dismiss()
        }
        vc.onCancel = { dismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

/// UIKit controller that uses UIImagePickerController for camera access
/// and passes the captured image through OCREngine.
final class CameraViewController: UIViewController {
    var onTextExtracted: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let ocrEngine = OCREngine()
    private var previewText: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        presentCamera()
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // Simulator fallback: use photo library
            presentPhotoPicker()
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            onCancel?()
            return
        }

        // Show processing indicator
        let alert = UIAlertController(title: "Procesando…", message: nil, preferredStyle: .alert)
        present(alert, animated: true)

        ocrEngine.recognizeText(from: image)

        // Poll for result (simple approach for hackathon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            alert.dismiss(animated: true) {
                let text = self?.ocrEngine.extractedText ?? ""
                if text.isEmpty {
                    self?.showError()
                } else {
                    self?.showPreview(text: text)
                }
            }
        }
    }

    private func showPreview(text: String) {
        let alert = UIAlertController(
            title: "Texto capturado",
            message: String(text.prefix(200)) + (text.count > 200 ? "…" : ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Usar este texto", style: .default) { [weak self] _ in
            self?.onTextExtracted?(text)
        })
        alert.addAction(UIAlertAction(title: "Reintentar", style: .cancel) { [weak self] _ in
            self?.presentCamera()
        })
        present(alert, animated: true)
    }

    private func showError() {
        let alert = UIAlertController(
            title: "No se detectó texto",
            message: "Asegúrate de que el texto sea claro y visible.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Reintentar", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.onCancel?()
        })
        present(alert, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        onCancel?()
    }
}
```

### 10.3 ReaderView.swift

```swift
import SwiftUI

struct ReaderView: View {
    let item: LibraryItem
    @State private var session = ReadingSession()
    @State private var tts = TTSEngine()
    @State private var ai = AIEngine()
    @State private var prefs = AppPreferences.shared
    @State private var showSettings = false
    @State private var showComprehension = false
    @State private var tappedWord: String? = nil
    @State private var tappedWordContext: String = ""
    @State private var showDefinitionCard = false
    @State private var definitionText: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            prefs.backgroundColor.color
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(.title2)
                    }
                    .accessibilityLabel("Configuración de lectura")

                    Spacer()

                    if session.isSimplifying {
                        ProgressView().scaleEffect(0.8)
                    } else if session.simplifiedText != nil {
                        Button("Original") {
                            session.simplifiedText = nil
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Button {
                        simplifyText()
                    } label: {
                        Label("Simplificar", systemImage: "sparkles")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .disabled(session.isSimplifying)
                    .accessibilityLabel("Simplificar texto con IA")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Main reading area
                ScrollView {
                    SyllableTextView(
                        text: session.simplifiedText ?? item.body,
                        highlightRange: tts.highlightRange,
                        prefs: prefs,
                        onWordTap: { word, context in
                            tappedWord = word
                            tappedWordContext = context
                            fetchDefinition(word: word, context: context)
                            showDefinitionCard = true
                        }
                    )
                    .padding(24)
                    .padding(.bottom, 120)
                }

                // Word definition card (overlaid)
                if showDefinitionCard {
                    WordDefinitionCard(
                        word: tappedWord ?? "",
                        definition: definitionText,
                        isLoading: session.isDefining
                    ) {
                        showDefinitionCard = false
                        definitionText = ""
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Bottom control bar
            ReadingControlBar(
                isPlaying: tts.isPlaying,
                speed: $prefs.readingSpeed,
                onPlayPause: {
                    if tts.isPlaying {
                        tts.pause()
                    } else if tts.currentWordIndex >= 0 {
                        tts.resume()
                    } else {
                        startReading()
                    }
                },
                onStop: {
                    tts.stop()
                },
                onComplete: {
                    generateComprehension()
                    showComprehension = true
                }
            )
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            prepareSession()
            LibraryStore.shared.markRead(item)
        }
        .onDisappear {
            tts.stop()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showComprehension) {
            ComprehensionView(
                questions: session.comprehensionQuestions,
                summary: "",
                text: item.body,
                ai: ai
            )
        }
    }

    // MARK: - Helpers

    private func prepareSession() {
        let text = item.body
        let (ranges, syllables) = SpanishSyllabifier.tokenize(text)
        session.wordRanges = ranges
        session.syllables = syllables
        session.fullText = text
        tts.load(text: text, wordRanges: ranges, syllables: syllables)
    }

    private func startReading() {
        tts.play(speed: prefs.readingSpeed)
    }

    private func simplifyText() {
        session.isSimplifying = true
        Task {
            do {
                let simplified = try await ai.simplify(text: item.body)
                await MainActor.run {
                    session.simplifiedText = simplified
                    session.isSimplifying = false
                    // Re-prepare TTS with new text
                    let (ranges, syllables) = SpanishSyllabifier.tokenize(simplified)
                    tts.load(text: simplified, wordRanges: ranges, syllables: syllables)
                }
            } catch {
                await MainActor.run {
                    session.isSimplifying = false
                }
            }
        }
    }

    private func fetchDefinition(word: String, context: String) {
        session.isDefining = true
        definitionText = ""
        Task {
            do {
                let def = try await ai.define(word: word, context: context)
                await MainActor.run {
                    definitionText = def
                    session.isDefining = false
                }
            } catch {
                await MainActor.run {
                    definitionText = "No se pudo obtener la definición."
                    session.isDefining = false
                }
            }
        }
    }

    private func generateComprehension() {
        Task {
            do {
                let questions = try await ai.generateQuestions(for: item.body)
                await MainActor.run {
                    session.comprehensionQuestions = questions.map {
                        ComprehensionQuestion(question: $0)
                    }
                }
            } catch { }
        }
    }
}
```

### 10.4 SyllableTextView.swift

```swift
import SwiftUI

struct SyllableTextView: View {
    let text: String
    let highlightRange: Range<String.Index>?
    let prefs: AppPreferences
    let onWordTap: (String, String) -> Void

    var body: some View {
        Text(buildAttributedString())
            .font(.custom(prefs.fontName, size: prefs.fontSize))
            .tracking(prefs.letterSpacing)
            .lineSpacing(prefs.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { location in
                // Word tap detection via UITextView or simple word extraction
                // Simplified: extract tapped word from gesture
            }
            .accessibilityLabel(text)
    }

    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(text)

        // Apply base text color
        attributed.foregroundColor = .primary

        // Apply syllable highlight
        if let range = highlightRange,
           let attrRange = Range(range, in: attributed) {
            attributed[attrRange].backgroundColor = .init(
                UIColor.systemYellow.withAlphaComponent(0.5)
            )
        }

        return attributed
    }
}
```

### 10.5 ReadingControlBar.swift

```swift
import SwiftUI

struct ReadingControlBar: View {
    let isPlaying: Bool
    @Binding var speed: Double
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Speed slider
            HStack {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Slider(value: $speed, in: 0.1...0.6, step: 0.05)
                    .accessibilityLabel("Velocidad de lectura")
                    .accessibilityValue(speedLabel)
                Image(systemName: "hare.fill")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)

            // Playback buttons
            HStack(spacing: 32) {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Detener lectura")

                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel(isPlaying ? "Pausar" : "Reproducir")

                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                }
                .accessibilityLabel("Marcar como leído y ver comprensión")
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }

    private var speedLabel: String {
        switch speed {
        case ..<0.2: return "Muy lento"
        case ..<0.35: return "Lento"
        case ..<0.5: return "Normal"
        default: return "Rápido"
        }
    }
}
```

### 10.6 WordDefinitionCard.swift

```swift
import SwiftUI

struct WordDefinitionCard: View {
    let word: String
    let definition: String
    let isLoading: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(word.capitalized)
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Cerrar definición")
            }

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Buscando definición…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(definition)
                    .font(.subheadline)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 140)
        .shadow(color: .black.opacity(0.12), radius: 10)
        .accessibilityElement(children: .combine)
    }
}
```

### 10.7 SettingsView.swift

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prefs = AppPreferences.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Texto") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tamaño: \(Int(prefs.fontSize))pt")
                            Spacer()
                        }
                        Slider(value: $prefs.fontSize, in: 16...40, step: 1)
                            .accessibilityLabel("Tamaño de fuente, \(Int(prefs.fontSize)) puntos")
                    }

                    VStack(alignment: .leading) {
                        Text("Espaciado entre letras: \(Int(prefs.letterSpacing))")
                        Slider(value: $prefs.letterSpacing, in: 0...8, step: 0.5)
                            .accessibilityLabel("Espaciado entre letras")
                    }

                    VStack(alignment: .leading) {
                        Text("Espaciado entre líneas: \(Int(prefs.lineSpacing))")
                        Slider(value: $prefs.lineSpacing, in: 4...28, step: 1)
                            .accessibilityLabel("Espaciado entre líneas")
                    }

                    Toggle("Fuente OpenDyslexic", isOn: $prefs.useOpenDyslexic)
                        .accessibilityLabel("Usar fuente especializada para dislexia")
                }

                Section("Lectura en voz alta") {
                    VStack(alignment: .leading) {
                        Text("Velocidad: \(speedLabel)")
                        Slider(value: $prefs.readingSpeed, in: 0.1...0.6, step: 0.05)
                            .accessibilityLabel("Velocidad de lectura, \(speedLabel)")
                    }
                }

                Section("Color de fondo") {
                    ForEach(BackgroundOption.allCases) { option in
                        HStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            Text(option.rawValue)
                            Spacer()
                            if prefs.backgroundColor == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { prefs.backgroundColor = option }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(prefs.backgroundColor == option ? .isSelected : [])
                    }
                }

                Section("Vista previa") {
                    Text("El texto se verá así cuando leas.")
                        .font(.custom(prefs.fontName, size: prefs.fontSize))
                        .tracking(prefs.letterSpacing)
                        .lineSpacing(prefs.lineSpacing)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(prefs.backgroundColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var speedLabel: String {
        switch prefs.readingSpeed {
        case ..<0.2: return "Muy lento"
        case ..<0.35: return "Lento"
        case ..<0.5: return "Normal"
        default: return "Rápido"
        }
    }
}
```

### 10.8 ComprehensionView.swift

```swift
import SwiftUI

struct ComprehensionView: View {
    @State var questions: [ComprehensionQuestion]
    let summary: String
    let text: String
    let ai: AIEngine
    @Environment(\.dismiss) private var dismiss
    @State private var computedSummary: String = ""
    @State private var isLoadingSummary = false
    @State private var allAnswered = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("¿Entendiste lo que leíste?")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    if questions.isEmpty {
                        ProgressView("Generando preguntas…")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach($questions) { $q in
                            QuestionCard(question: $q)
                        }
                        .padding(.horizontal)
                    }

                    if allAnswered {
                        Divider().padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Resumen")
                                .font(.headline)

                            if isLoadingSummary {
                                ProgressView()
                            } else {
                                Text(computedSummary)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal)
                        .task {
                            await loadSummary()
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Comprensión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onChange(of: questions) { _, newVal in
                allAnswered = newVal.allSatisfy { $0.answer != nil }
            }
        }
    }

    private func loadSummary() async {
        guard computedSummary.isEmpty else { return }
        isLoadingSummary = true
        do {
            computedSummary = try await ai.summarize(text: text)
        } catch {
            computedSummary = "No se pudo generar el resumen."
        }
        isLoadingSummary = false
    }
}

struct QuestionCard: View {
    @Binding var question: ComprehensionQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.body.weight(.medium))

            HStack(spacing: 16) {
                AnswerButton(
                    label: "Sí",
                    selected: question.answer == true,
                    color: .green
                ) { question.answer = true }

                AnswerButton(
                    label: "No",
                    selected: question.answer == false,
                    color: .red
                ) { question.answer = false }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AnswerButton: View {
    let label: String
    let selected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? color : Color(.systemGray5))
                .foregroundColor(selected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
```

---

## 11. Navigation & App Shell

### 11.1 DislexIAApp.swift

```swift
import SwiftUI

@main
struct DislexIAApp: App {
    init() {
        LibraryStore.shared.seedIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .modelContainer(LibraryStore.shared.container)
        }
    }
}
```

---

## 12. Accessibility Requirements

Every view must implement these. Non-negotiable.

```swift
// 1. Every interactive element needs accessibilityLabel
Button { } label: { Image(systemName: "camera") }
    .accessibilityLabel("Capturar texto con cámara")

// 2. Dynamic Type — always use .font(.body), .font(.headline) etc, never fixed sizes
// EXCEPTION: ReaderView uses user-controlled font size, which is intentional

// 3. VoiceOver grouping for compound elements
VStack { Text(title); Text(subtitle) }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title). \(subtitle)")

// 4. Selected state for toggles/pickers
.accessibilityAddTraits(isSelected ? .isSelected : [])

// 5. Haptic feedback on play/pause
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred()

// 6. Minimum tap target: 44×44pt for all interactive elements
.frame(minWidth: 44, minHeight: 44)

// 7. Reduce Motion — skip animations if enabled
@Environment(\.accessibilityReduceMotion) var reduceMotion
withAnimation(reduceMotion ? .none : .easeInOut) { ... }
```

---

## 13. Assets & Fonts

### 13.1 Font setup

Download OpenDyslexic from: https://opendyslexic.org (OFL license — free for commercial use)

Files needed:
- `OpenDyslexic-Regular.otf`
- `OpenDyslexic-Bold.otf` (optional)

Add to Xcode project: drag into Resources group → check "Add to target: DislexIA"

### 13.2 Info.plist font registration (add manually or via Xcode's Info tab)

```xml
<key>UIAppFonts</key>
<array>
    <string>OpenDyslexic-Regular.otf</string>
    <string>OpenDyslexic-Bold.otf</string>
</array>
```

### 13.3 Verify font loads

```swift
// In AppDelegate or on first launch — will print available names
UIFont.familyNames.forEach { family in
    UIFont.fontNames(forFamilyName: family).forEach { print($0) }
}
// Should print: OpenDyslexic, OpenDyslexic-Bold
```

---

## 14. Info.plist & Entitlements

### 14.1 Required Info.plist keys

```xml
<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>DislexIA necesita la cámara para capturar texto de libros, carteles y documentos.</string>

<!-- Photo library (simulator fallback) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>DislexIA puede importar imágenes con texto de tu biblioteca de fotos.</string>

<!-- Fonts -->
<key>UIAppFonts</key>
<array>
    <string>OpenDyslexic-Regular.otf</string>
    <string>OpenDyslexic-Bold.otf</string>
</array>

<!-- Supported orientations -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

### 14.2 No special entitlements required

Foundation Models, Vision, AVFoundation, NaturalLanguage and SwiftData are all standard capabilities requiring no special entitlements.

---

## 15. Pre-loaded Library Content

### 15.1 PreloadedLibrary.swift

```swift
import Foundation

enum PreloadedLibrary {
    static let items: [LibraryItem] = basicTexts + intermediateTexts + advancedTexts

    // MARK: - Básico

    static let basicTexts: [LibraryItem] = [
        LibraryItem(
            title: "El sol y la luna",
            body: """
            El sol brilla de día. La luna brilla de noche. \
            El sol es grande y amarillo. La luna es blanca y redonda. \
            De día hace calor. De noche hace frío. \
            El sol y la luna cuidan la Tierra.
            """,
            level: .basic
        ),
        LibraryItem(
            title: "Mi mascota",
            body: """
            Tengo un perro que se llama Canelo. \
            Canelo es café con manchas blancas. \
            Le gusta correr y jugar con su pelota. \
            Todos los días le doy de comer y agua fresca. \
            Canelo me hace muy feliz.
            """,
            level: .basic
        ),
        LibraryItem(
            title: "La hormiga trabajadora",
            body: """
            Una hormiga caminaba por el campo buscando comida. \
            Encontró una semilla grande y la cargó hasta su casa. \
            La semilla era muy pesada, pero la hormiga no se rindió. \
            Cuando llegó a casa, sus amigas la ayudaron a guardar la semilla. \
            Juntas tendrían comida para el invierno.
            """,
            level: .basic
        ),
        LibraryItem(
            title: "Las estaciones del año",
            body: """
            En primavera florecen las plantas. Hace calor y llueve. \
            En verano el sol calienta mucho. Los días son largos. \
            En otoño las hojas de los árboles cambian de color y caen. \
            En invierno hace frío y a veces nieva. \
            Cada estación tiene algo especial.
            """,
            level: .basic
        ),
        LibraryItem(
            title: "El panadero del pueblo",
            body: """
            Don Ramón se levanta muy temprano cada mañana. \
            Enciende su horno y prepara la masa del pan. \
            Amasa, da forma y hornea los bolillos. \
            A las siete de la mañana el pan ya está listo. \
            El olor rico del pan llena todo el pueblo.
            """,
            level: .basic
        )
    ]

    // MARK: - Intermedio

    static let intermediateTexts: [LibraryItem] = [
        LibraryItem(
            title: "El agua que bebemos",
            body: """
            El agua es un recurso muy valioso. Sin agua no puede existir la vida. \
            La mayor parte del agua de la Tierra está en los océanos, pero esa agua es salada. \
            Solo una pequeña parte es agua dulce, que es la que podemos beber. \
            El agua dulce se encuentra en ríos, lagos y manantiales. \
            Es importante cuidar el agua: cerrar la llave cuando no la usamos \
            y evitar contaminar los ríos. Todos podemos ayudar a conservarla.
            """,
            level: .intermediate
        ),
        LibraryItem(
            title: "La selva tropical",
            body: """
            La selva tropical es uno de los ecosistemas más ricos del planeta. \
            En ella viven millones de especies de plantas, animales e insectos. \
            Los árboles son tan altos que forman un techo verde llamado dosel, \
            que protege a las plantas pequeñas del sol directo. \
            Las selvas producen mucho oxígeno y regulan el clima de la Tierra. \
            Por eso es tan importante protegerlas de la deforestación.
            """,
            level: .intermediate
        ),
        LibraryItem(
            title: "Cómo funciona el cerebro",
            body: """
            El cerebro es el órgano más complejo de nuestro cuerpo. \
            Pesa aproximadamente 1.4 kilogramos y tiene forma de nuez. \
            Está formado por miles de millones de células llamadas neuronas. \
            Las neuronas se comunican entre sí mediante señales eléctricas y químicas. \
            El cerebro controla todos los movimientos del cuerpo, los pensamientos, \
            los recuerdos y las emociones. Mientras dormimos, el cerebro sigue trabajando \
            para procesar lo que aprendimos durante el día.
            """,
            level: .intermediate
        )
    ]

    // MARK: - Avanzado

    static let advancedTexts: [LibraryItem] = [
        LibraryItem(
            title: "La Revolución Industrial",
            body: """
            La Revolución Industrial fue un periodo de transformación económica y social \
            que comenzó en Inglaterra a finales del siglo XVIII. La invención de la máquina \
            de vapor permitió mecanizar procesos que antes se hacían a mano, lo que aumentó \
            enormemente la producción de bienes. Las fábricas reemplazaron a los talleres \
            artesanales y miles de personas migraron del campo a las ciudades en busca de trabajo. \
            Este cambio trajo avances tecnológicos importantes, pero también nuevos problemas \
            sociales como las largas jornadas laborales, el trabajo infantil y la contaminación. \
            Sus efectos moldearon el mundo moderno tal como lo conocemos hoy.
            """,
            level: .advanced
        ),
        LibraryItem(
            title: "La inteligencia artificial",
            body: """
            La inteligencia artificial es una rama de la informática que busca crear sistemas \
            capaces de realizar tareas que normalmente requieren inteligencia humana, como \
            reconocer imágenes, entender lenguaje natural o tomar decisiones. \
            Los sistemas de IA aprenden a partir de grandes cantidades de datos mediante \
            algoritmos de aprendizaje automático. Hoy en día la IA está presente en muchos \
            aspectos de nuestra vida cotidiana: en los asistentes de voz, en las recomendaciones \
            de plataformas de streaming, en el diagnóstico médico y en los vehículos autónomos. \
            A medida que esta tecnología avanza, surgen importantes preguntas éticas sobre \
            privacidad, empleo y el impacto en la sociedad.
            """,
            level: .advanced
        )
    ]
}
```

---

## 16. Edge Cases & Error Handling

### 16.1 OCR edge cases

```swift
// Multi-column text: Vision sorts by bounding box — handled in OCREngine sorting logic.
// Curved/perspective text: Vision handles this natively with .accurate level.
// Low light / blurry: show retry dialog (already implemented in CameraViewController).
// Empty image: guard on empty extractedText → showError().
// Very long text (>5000 chars): truncate to 3000 before passing to FoundationModels.
let safeText = text.count > 3000 ? String(text.prefix(3000)) + "…" : text
```

### 16.2 Foundation Models unavailability

```swift
// Foundation Models requires:
// - Physical device (NOT simulator)
// - iOS 18.0+
// - Sufficient storage (~2GB for model)
// - Device: A12 Bionic or later

// Always guard:
guard LanguageModelSession.isSupported else {
    // Show graceful degradation message
    return
}
```

### 16.3 TTS voice fallback

```swift
// es-MX may not be installed on all devices
let voice = AVSpeechSynthesisVoice(language: "es-MX")
         ?? AVSpeechSynthesisVoice(language: "es-ES")
         ?? AVSpeechSynthesisVoice(language: "es")
// If all fail, use system default — still readable
```

### 16.4 SwiftData migration

```swift
// If schema changes during development, increment version:
let config = ModelConfiguration("DislexIA", schema: schema, isStoredInMemoryOnly: false)
// Or wipe on schema mismatch (acceptable for hackathon):
let config = ModelConfiguration("DislexIA", schema: schema, allowsSave: true)
```

### 16.5 OpenDyslexic font not loading

```swift
// Fallback in AppPreferences.fontName:
var fontName: String {
    if useOpenDyslexic {
        // Verify font is available
        if UIFont(name: "OpenDyslexic", size: 17) != nil {
            return "OpenDyslexic"
        }
    }
    return UIFont.systemFont(ofSize: 17).fontName
}
```

---

## 17. Build & Test Checklist

### Functional tests

- [ ] App launches without crash on iOS 18 simulator
- [ ] Library shows preloaded texts in 3 levels
- [ ] Camera → photo → OCR → ReaderView pipeline works end-to-end
- [ ] Photo library picker works in simulator (camera unavailable)
- [ ] TTS plays on physical device with es-MX voice
- [ ] Syllable highlight animates during TTS playback
- [ ] Tap word → definition card appears
- [ ] Simplify button → text changes to simplified version
- [ ] Comprehension questions generate and display
- [ ] Settings sliders change font size / spacing in real-time
- [ ] Background color picker changes color immediately
- [ ] OpenDyslexic font renders correctly
- [ ] Adding text via camera saves to library
- [ ] Swipe to delete custom items works

### Device-only tests (simulator insufficient)

- [ ] Foundation Models responds (requires physical device, iOS 18, A12+)
- [ ] Camera capture works
- [ ] TTS voice quality in es-MX
- [ ] Haptic feedback on play/pause

### Accessibility tests

- [ ] VoiceOver navigates all 5 screens without getting stuck
- [ ] All buttons announce their label correctly
- [ ] Dynamic Type extra-large doesn't break layouts
- [ ] Contrast ratio ≥ 4.5:1 on all color combinations

### Performance targets

- [ ] OCR completes in < 2 seconds for a standard book page
- [ ] App launch to Library: < 1.5 seconds
- [ ] Syllabifier processes 1000-word text in < 100ms

---

*DislexIA — Full Developer Specification*  
*Swift Challenge Fest 2026 — Tecnológico de Monterrey*  
*Ready for Claude Code*
