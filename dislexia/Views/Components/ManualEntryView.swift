import SwiftUI

struct ManualEntryView: View {
    let onSave: (String, String, DifficultyLevel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var level: DifficultyLevel = .basic
    @State private var showValidationAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Título") {
                    TextField("Nombre del texto", text: $title)
                        .accessibilityLabel("Título del texto")
                }

                Section("Nivel") {
                    Picker("Nivel de dificultad", selection: $level) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { lvl in
                            Text(lvl.rawValue).tag(lvl)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Nivel de dificultad")
                }

                Section("Contenido") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .font(.body)
                        .accessibilityLabel("Contenido del texto")
                }
            }
            .navigationTitle("Nuevo texto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .accessibilityLabel("Cancelar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        else {
                            showValidationAlert = true
                            return
                        }
                        onSave(title, content, level)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Guardar texto")
                }
            }
            .alert("Campos incompletos", isPresented: $showValidationAlert) {
                Button("OK") {}
            } message: {
                Text("Por favor ingresa un título y el contenido del texto.")
            }
        }
    }
}

#Preview {
    ManualEntryView { _, _, _ in }
}
