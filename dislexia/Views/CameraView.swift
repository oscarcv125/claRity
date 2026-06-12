import SwiftUI
import UIKit

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
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            presentPicker(source: .camera)
        } else {
            presentPicker(source: .photoLibrary)
        }
    }

    private func presentPicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func processImage(_ image: UIImage) {
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
            await ocrEngine.recognizeText(from: image)
            alert.dismiss(animated: true) {
                let text = self.ocrEngine.extractedText
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

// MARK: - UIImagePickerControllerDelegate

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            onCancel?()
            return
        }
        processImage(image)
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
