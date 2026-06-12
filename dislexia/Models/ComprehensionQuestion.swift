import Foundation

struct ComprehensionQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String

    // docs
    var expectedAnswer: Bool? = nil
    var answer: Bool? = nil

    // docs
    var options: [String] = []
    // docs
    var correctOptionIndex: Int? = nil
    // docs
    var selectedOptionIndex: Int? = nil

    var isMultipleChoice: Bool { !options.isEmpty }

    // docs
    var isAnswered: Bool {
        isMultipleChoice ? selectedOptionIndex != nil : answer != nil
    }

    // docs
    var isCorrect: Bool? {
        if isMultipleChoice {
            guard let selectedOptionIndex, let correctOptionIndex else { return nil }
            return selectedOptionIndex == correctOptionIndex
        }
        guard let answer, let expectedAnswer else { return nil }
        return answer == expectedAnswer
    }

    static func == (lhs: ComprehensionQuestion, rhs: ComprehensionQuestion) -> Bool {
        lhs.id == rhs.id
            && lhs.answer == rhs.answer
            && lhs.selectedOptionIndex == rhs.selectedOptionIndex
    }
}
