import SwiftUI

struct EditStorageSheet: View {
    let storage: Storage
    @Binding var isPresented: Bool
    var onSave: (String) -> Void

    @State private var name: String

    init(storage: Storage, isPresented: Binding<Bool>, onSave: @escaping (String) -> Void) {
        self.storage = storage
        self._isPresented = isPresented
        self.onSave = onSave
        _name = State(initialValue: storage.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Storage") {
                    TextField("Storage Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .appGradientBackground()
    }
}
