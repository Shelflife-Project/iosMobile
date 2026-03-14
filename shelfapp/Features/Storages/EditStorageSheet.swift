import SwiftUI

struct EditStorageSheet: View {
    let storage: Storage
    @Binding var isPresented: Bool
    var onSave: (String, Bool, Bool) -> Void

    @State private var name: String
    @State private var runningLowEnabled: Bool
    @State private var shoppingListEnabled: Bool

    init(storage: Storage, isPresented: Binding<Bool>, onSave: @escaping (String, Bool, Bool) -> Void) {
        self.storage = storage
        self._isPresented = isPresented
        self.onSave = onSave

        let storageId = storage.serverId ?? 0
        _name = State(initialValue: storage.name)
        _runningLowEnabled = State(initialValue: UserDefaults.standard.object(forKey: "storage_\(storageId)_runningLowEnabled") as? Bool ?? true)
        _shoppingListEnabled = State(initialValue: UserDefaults.standard.object(forKey: "storage_\(storageId)_shoppingListEnabled") as? Bool ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Storage") {
                    TextField("Storage Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Controllers") {
                    Toggle("Running Low", isOn: $runningLowEnabled)
                    Toggle("Shopping List", isOn: $shoppingListEnabled)
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
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            runningLowEnabled,
                            shoppingListEnabled
                        )
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .appGradientBackground()
    }
}
