import AVFoundation
import Observation
import UIKit

@Observable
@MainActor
final class TTSEngine: NSObject {

    // MARK: - Public state

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

        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Public API

    func load(text: String, wordRanges: [Range<String.Index>], syllables: [[String]]) {
        fullText = text
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
            ?? AVSpeechSynthesisVoice(language: "es")
        utterance.postUtteranceDelay = 0.05
        utterance.preUtteranceDelay = 0

        synthesizer.speak(utterance)
        isPlaying = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        cancelSyllableTimers()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPlaying = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        let range = wordRanges[wordIndex]
        let substring = String(fullText[range.lowerBound...])
        let utterance = AVSpeechUtterance(string: substring)
        utterance.rate = readingSpeed
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
            ?? AVSpeechSynthesisVoice(language: "es-ES")
        synthesizer.speak(utterance)
        isPlaying = true
        currentWordIndex = wordIndex - 1
    }

    // MARK: - Syllable animation

    private func animateSyllables(wordIndex: Int, wordDurationSeconds: Double) {
        cancelSyllableTimers()
        let syls = syllables[safe: wordIndex] ?? []
        guard !syls.isEmpty else { return }
        let interval = wordDurationSeconds / Double(syls.count)

        for (idx, _) in syls.enumerated() {
            let delay = interval * Double(idx)
            let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
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
        let syls = syllables[safe: wordIndex] ?? [String(fullText[wordRange])]

        var offset = fullText.distance(from: fullText.startIndex, to: wordRange.lowerBound)
        for i in 0..<syllableIndex {
            offset += syls[safe: i]?.count ?? 0
        }

        let sylLen = syls[safe: syllableIndex]?.count ?? 0
        guard
            let start = fullText.index(fullText.startIndex, offsetBy: offset, limitedBy: fullText.endIndex),
            let end   = fullText.index(start, offsetBy: sylLen, limitedBy: fullText.endIndex)
        else { return }
        highlightRange = start..<end
    }

    private func cancelSyllableTimers() {
        syllableTimers.forEach { $0.invalidate() }
        syllableTimers = []
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSEngine: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let range = Range(characterRange, in: self.fullText) else { return }

            let wordIdx = self.wordRanges.firstIndex { $0.overlaps(range) } ?? -1
            guard wordIdx >= 0 else { return }

            self.currentWordIndex = wordIdx

            let sylCount = max(1, self.syllables[safe: wordIdx]?.count ?? 1)
            let baseDuration = Double(sylCount) * 0.18 * (0.5 / Double(self.readingSpeed))
            self.animateSyllables(wordIndex: wordIdx, wordDurationSeconds: baseDuration)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.currentWordIndex = -1
            self.highlightRange = nil
            self.cancelSyllableTimers()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.isPlaying = false
            self?.cancelSyllableTimers()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.isPlaying = true
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
