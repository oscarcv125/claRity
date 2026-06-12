import Foundation
import Observation

/// Ephemeral — lives only while ReaderView is active. Not persisted.
@Observable
@MainActor
final class ReadingSession {
    var fullText: String = ""
    var syllables: [[String]] = []
    var wordRanges: [Range<String.Index>] = []

    var isPlaying: Bool = false
    var currentWordIndex: Int = -1
    var currentSyllableIndex: Int = -1
    var highlightRange: Range<String.Index>? = nil

    var simplifiedText: String? = nil
    var isSimplifying: Bool = false
    var selectedWordDefinition: String? = nil
    var isDefining: Bool = false

    var comprehensionQuestions: [ComprehensionQuestion] = []
    var isGeneratingQuestions: Bool = false
    var comprehensionComplete: Bool = false
}
