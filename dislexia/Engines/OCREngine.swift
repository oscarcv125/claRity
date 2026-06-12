@preconcurrency import Vision
import UIKit
import Observation

@Observable
@MainActor
final class OCREngine {
    var extractedText: String = ""
    var isProcessing: Bool = false
    var error: String? = nil

    func recognizeText(from image: UIImage) async {
        guard let cgImage = image.cgImage else {
            error = "No se pudo procesar la imagen."
            return
        }

        isProcessing = true
        error = nil
        extractedText = ""

        do {
            let text = try await performOCR(on: cgImage)
            extractedText = text
        } catch {
            self.error = "Error OCR: \(error.localizedDescription)"
        }
        isProcessing = false
    }

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, err in
                if let err {
                    continuation.resume(throwing: err)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let sorted = observations.sorted {
                    let y0 = $0.boundingBox.minY
                    let y1 = $1.boundingBox.minY
                    if abs(y0 - y1) > 0.05 { return y0 > y1 }
                    return $0.boundingBox.minX < $1.boundingBox.minX
                }
                let text = sorted
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                continuation.resume(returning: text)
            }

            request.recognitionLanguages = ["es-MX", "es-ES", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
