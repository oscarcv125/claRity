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

    func define(word: String, context: String) async throws -> WordDefinition {
        let session = try makeSession()
        let prompt = """
        Define la palabra "\(word)" considerando sus diferentes significados comunes para niños de 10 años.
        Contexto donde se usa: "\(context)"

        Responde estrictamente con el siguiente formato, sin explicaciones, introducciones ni rodeos:
        SIGNIFICADO 1: [Primer significado común]
        SIGNIFICADO 2: [Segundo significado común]
        SIGNIFICADO 3: [Tercer significado común] (opcional, solo si existe otro significado común)
        USO_ACTUAL: [El número del significado que corresponde al contexto]
        EJEMPLO: [Una oración corta de ejemplo usando el significado actual]
        """
        let response = try await session.respond(to: prompt)
        return parseDefinition(from: response.content, for: word)
    }

    private func parseDefinition(from text: String, for word: String) -> WordDefinition {
        var senses: [WordDefinition.Sense] = []
        var useActual: Int = 1
        var example: String? = nil
        
        let lines = text.components(separatedBy: .newlines)
        var meaningTexts: [Int: String] = [:]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("SIGNIFICADO"), let colonIndex = trimmed.firstIndex(of: ":") {
                let prefix = trimmed[..<colonIndex] // e.g. "SIGNIFICADO 1"
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                
                // Extract number
                let numString = prefix.components(separatedBy: .whitespaces).last ?? ""
                if let num = Int(numString) {
                    meaningTexts[num] = content
                }
            } else if trimmed.hasPrefix("USO_ACTUAL"), let colonIndex = trimmed.firstIndex(of: ":") {
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                useActual = Int(content) ?? 1
            } else if trimmed.hasPrefix("EJEMPLO"), let colonIndex = trimmed.firstIndex(of: ":") {
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                example = content
            }
        }
        
        // Sort and map to Senses
        let sortedKeys = meaningTexts.keys.sorted()
        for key in sortedKeys {
            if let meaning = meaningTexts[key] {
                senses.append(WordDefinition.Sense(text: meaning, isCurrent: key == useActual))
            }
        }
        
        // Fallback if no meanings parsed correctly
        if senses.isEmpty {
            senses.append(WordDefinition.Sense(text: text, isCurrent: true))
        }
        
        return WordDefinition(word: word, senses: senses, example: example)
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
