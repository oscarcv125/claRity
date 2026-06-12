import Foundation

struct ComprehensionQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String

    // MARK: Sí / No
    /// Respuesta correcta esperada (generada por la IA junto con la pregunta).
    var expectedAnswer: Bool? = nil
    var answer: Bool? = nil

    // MARK: Opción múltiple (experimental)
    /// Opciones de respuesta. Vacío = pregunta de Sí/No.
    var options: [String] = []
    /// Índice de la opción correcta dentro de `options`.
    var correctOptionIndex: Int? = nil
    /// Índice de la opción elegida por el usuario.
    var selectedOptionIndex: Int? = nil

    var isMultipleChoice: Bool { !options.isEmpty }

    /// Verdadero cuando el usuario ya respondió (en cualquier modalidad).
    var isAnswered: Bool {
        isMultipleChoice ? selectedOptionIndex != nil : answer != nil
    }

    /// `nil` si aún no se responde o no hay respuesta esperada.
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
