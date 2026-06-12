import Foundation

public struct WordDefinition: Sendable, Codable {
    public struct Sense: Identifiable, Sendable, Codable {
        public let id: UUID
        public let text: String
        public let isCurrent: Bool

        public init(id: UUID = UUID(), text: String, isCurrent: Bool) {
            self.id = id
            self.text = text
            self.isCurrent = isCurrent
        }
    }

    public let word: String
    public let senses: [Sense]
    public let example: String?

    public init(word: String, senses: [Sense], example: String?) {
        self.word = word
        self.senses = senses
        self.example = example
    }
}
