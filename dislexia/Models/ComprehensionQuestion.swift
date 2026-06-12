import Foundation

struct ComprehensionQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String
    var answer: Bool? = nil

    static func == (lhs: ComprehensionQuestion, rhs: ComprehensionQuestion) -> Bool {
        lhs.id == rhs.id && lhs.answer == rhs.answer
    }
}
