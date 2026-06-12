import Foundation
import Observation
import FoundationModels

@Observable
@MainActor
final class AIEngine {

    enum AIError: LocalizedError {
        case modelUnavailable
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "El modelo de IA no está disponible en este dispositivo. Requiere Apple Intelligence (iPhone con chip A17 Pro o posterior, iOS 18.1+)."
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
        \(text.prefix(2000))
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
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw AIError.modelUnavailable
        }
        return LanguageModelSession(model: model)
    }
}
