import SwiftUI
import UIKit
import VisionKit

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onTextExtracted = { text in
            onCapture(text)
            dismiss()
        }
        vc.onCancel = { dismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

// MARK: - Camera view controller

final class CameraViewController: UIViewController {
    var onTextExtracted: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let ocrEngine = OCREngine()

    private var hasPresented = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasPresented {
            hasPresented = true
            presentSource()
        }
    }

    private func presentSource() {
        if VNDocumentCameraViewController.isSupported {
            // Escáner de documentos de Apple: detecta los bordes de la página
            // y permite ajustar el recorte — evita que se cuele texto de la
            // página de al lado.
            let scanner = VNDocumentCameraViewController()
            scanner.delegate = self
            present(scanner, animated: true)
        } else {
            // Simulador / sin cámara: galería con recorte nativo.
            presentLibraryPicker()
        }
    }

    private func presentLibraryPicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func processImages(_ images: [UIImage]) {
        let alert = UIAlertController(title: "Procesando texto…", message: nil, preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        alert.view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -16)
        ])
        present(alert, animated: true)

        Task { @MainActor in
            var pages: [String] = []
            for image in images {
                await ocrEngine.recognizeText(from: image)
                let pageText = ocrEngine.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !pageText.isEmpty { pages.append(pageText) }
            }
            let text = pages.joined(separator: "\n\n")
            alert.dismiss(animated: true) {
                if text.isEmpty {
                    self.showError()
                } else {
                    self.showPreview(text: text)
                }
            }
        }
    }

    private func showPreview(text: String) {
        let preview = String(text.prefix(300)) + (text.count > 300 ? "…" : "")
        let alert = UIAlertController(
            title: "Texto capturado",
            message: preview,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Usar este texto", style: .default) { [weak self] _ in
            self?.onTextExtracted?(text)
        })
        alert.addAction(UIAlertAction(title: "Reintentar", style: .cancel) { [weak self] _ in
            self?.presentSource()
        })
        present(alert, animated: true)
    }

    private func showError() {
        let alert = UIAlertController(
            title: "No se detectó texto",
            message: "Asegúrate de que el texto sea claro y visible.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Reintentar", style: .default) { [weak self] _ in
            self?.presentSource()
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.onCancel?()
        })
        present(alert, animated: true)
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension CameraViewController: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
        controller.dismiss(animated: true) { [weak self] in
            guard !images.isEmpty else {
                self?.onCancel?()
                return
            }
            self?.processImages(images)
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.showError()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate (fallback galería)

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else {
            onCancel?()
            return
        }
        processImages([image])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        onCancel?()
    }
}

#Preview {
    CameraView { text in
        print("Captured: \(text)")
    }
}
