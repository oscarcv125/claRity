import AVFoundation
import Observation
import UIKit

@Observable
@MainActor
final class TTSEngine: NSObject {


    var isPlaying: Bool = false
    var currentWordIndex: Int = -1
    var currentSyllableIndex: Int = -1
    var highlightRange: Range<String.Index>? = nil


    private let synthesizer = AVSpeechSynthesizer()
    private var wordRanges: [Range<String.Index>] = []
    private var syllables: [[String]] = []
    private var fullText: String = ""
    private var language: ReadingLanguage = .spanish
    private var readingSpeed: Float = 0.42
    private var syllableTimers: [Timer] = []
    // docs
    private var utteranceCharOffset: Int = 0
    // docs
    private var isPronouncingWord = false
    // docs
    private var speedRestartTask: Task<Void, Never>?
    // docs
    private var pendingSpeedRestart = false

    override init() {
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
    }


    func load(
        text: String,
        wordRanges: [Range<String.Index>],
        syllables: [[String]],
        language: ReadingLanguage = .spanish
    ) {
        fullText = text
        self.wordRanges = wordRanges
        self.syllables = syllables
        self.language = language
        stop()
    }

    func play(speed: Double = 0.42) {
        guard !fullText.isEmpty else { return }
        readingSpeed = Float(speed)
        utteranceCharOffset = 0
        isPronouncingWord = false
        pendingSpeedRestart = false
        speedRestartTask?.cancel()
        // logica
        synthesizer.stopSpeaking(at: .immediate)
        cancelSyllableTimers()

        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: fullText)
        utterance.rate = readingSpeed
        utterance.voice = voice
        utterance.postUtteranceDelay = 0.05
        utterance.preUtteranceDelay = 0

        synthesizer.speak(utterance)
        isPlaying = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func pause() {
        guard synthesizer.isSpeaking else {
            isPlaying = false
            return
        }
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        cancelSyllableTimers()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func resume() {
        // logica
        if pendingSpeedRestart || !synthesizer.isPaused {
            pendingSpeedRestart = false
            if currentWordIndex >= 0 {
                seek(to: currentWordIndex)
            } else {
                play(speed: Double(readingSpeed))
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        synthesizer.continueSpeaking()
        isPlaying = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func stop() {
        speedRestartTask?.cancel()
        pendingSpeedRestart = false
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPronouncingWord = false
        currentWordIndex = -1
        currentSyllableIndex = -1
        highlightRange = nil
        utteranceCharOffset = 0
        cancelSyllableTimers()
        // logica
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // docs
    func seek(to wordIndex: Int) {
        guard wordIndex >= 0, wordIndex < wordRanges.count else { return }
        synthesizer.stopSpeaking(at: .immediate)
        cancelSyllableTimers()
        isPronouncingWord = false
        // logica
        pendingSpeedRestart = false

        let range = wordRanges[wordIndex]
        utteranceCharOffset = NSRange(range.lowerBound..<fullText.endIndex, in: fullText).location

        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: String(fullText[range.lowerBound...]))
        utterance.rate = readingSpeed
        utterance.voice = voice
        synthesizer.speak(utterance)
        isPlaying = true
    }

    // docs
    func setSpeed(_ speed: Double) {
        let newRate = Float(speed)
        guard newRate != readingSpeed else { return }
        readingSpeed = newRate

        if isPlaying {
            speedRestartTask?.cancel()
            speedRestartTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled, let self, self.isPlaying else { return }
                self.seek(to: max(self.currentWordIndex, 0))
            }
        } else if currentWordIndex >= 0 {
            // logica
            pendingSpeedRestart = true
        }
    }

    // docs
    func pronounceSlowly(word: String) {
        synthesizer.stopSpeaking(at: .immediate)
        cancelSyllableTimers()
        isPlaying = false
        isPronouncingWord = true

        try? AVAudioSession.sharedInstance().setActive(true)

        let syls = language.syllabify(word)
        // logica
        let utterance = AVSpeechUtterance(string: syls.joined(separator: " ... "))
        utterance.rate = 0.25
        utterance.voice = voice
        synthesizer.speak(utterance)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // docs
    func speak(fragment: String, rate: Float = 0.3) {
        synthesizer.stopSpeaking(at: .immediate)
        cancelSyllableTimers()
        isPlaying = false
        isPronouncingWord = true

        try? AVAudioSession.sharedInstance().setActive(true)

        // logica
        let textToSpeak = fragment.count <= 2 ? " \(fragment) " : fragment
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.rate = rate
        utterance.voice = voice
        synthesizer.speak(utterance)
    }


    // docs
    private var voiceCache: [ReadingLanguage: AVSpeechSynthesisVoice] = [:]

    private var voice: AVSpeechSynthesisVoice? {
        // logica
        if AppPreferences.shared.usePersonalVoice,
           let personal = personalVoice(for: language) {
            return personal
        }
        return bestVoice(for: language)
    }

    // docs
    private func personalVoice(for language: ReadingLanguage) -> AVSpeechSynthesisVoice? {
        let personals = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.voiceTraits.contains(.isPersonalVoice) }
        return personals.first { $0.language.hasPrefix(language.rawValue) } ?? personals.first
    }

    // docs
    static var personalVoiceStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus {
        AVSpeechSynthesizer.personalVoiceAuthorizationStatus
    }

    // docs
    static var hasPersonalVoice: Bool {
        AVSpeechSynthesisVoice.speechVoices()
            .contains { $0.voiceTraits.contains(.isPersonalVoice) }
    }

    // docs
    static func requestPersonalVoiceAccess() async -> AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus {
        await withCheckedContinuation { continuation in
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // docs
    private func bestVoice(for language: ReadingLanguage) -> AVSpeechSynthesisVoice? {
        if let cached = voiceCache[language] { return cached }

        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { v in
            guard v.language.hasPrefix(language.rawValue) else { return false }
            // logica
            if v.voiceTraits.contains(.isNoveltyVoice) { return false }
            if v.voiceTraits.contains(.isPersonalVoice) { return false }
            return true
        }

        func score(_ v: AVSpeechSynthesisVoice) -> Int {
            var s: Int
            switch v.quality {
            case .premium:  s = 300
            case .enhanced: s = 200
            default:        s = 100
            }
            // logica
            if let idx = language.voiceCodes.firstIndex(of: v.language) {
                s += (language.voiceCodes.count - idx) * 10
            }
            return s
        }

        let best = candidates.max { score($0) < score($1) }
            ?? language.voiceCodes.lazy
                .compactMap { AVSpeechSynthesisVoice(language: $0) }
                .first

        if let best { voiceCache[language] = best }
        return best
    }


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


extension TTSEngine: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard !self.isPronouncingWord else { return }

            let adjusted = NSRange(
                location: characterRange.location + self.utteranceCharOffset,
                length: characterRange.length
            )
            guard let range = Range(adjusted, in: self.fullText) else { return }

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
            if self.isPronouncingWord {
                self.isPronouncingWord = false
                return
            }
            self.isPlaying = false
            self.currentWordIndex = -1
            self.highlightRange = nil
            self.cancelSyllableTimers()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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


private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
