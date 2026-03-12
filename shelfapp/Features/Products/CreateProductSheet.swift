import SwiftUI

struct CreateProductSheet: View {
    @Binding var isPresented: Bool
    var onSave: (String, String, Int) -> Void
    @State private var name = ""
    @State private var category = ""
    @State private var description = ""
    @State private var expirationDays = 7

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Product Description", text: $description)
                    TextField("Category", text: $category)
                        .textInputAutocapitalization(.words)
                }

                Section("Expiration") {
                    Stepper(
                        "Days: \(expirationDays)",
                        value: $expirationDays,
                        in: 0...365
                    )
                }
            }
            .navigationTitle("Create Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, category, expirationDays)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
