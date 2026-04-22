import SwiftUI

struct CreateProductSheet: View {
    @Binding var isPresented: Bool
    var onSave: (String, String, Int, String?) -> Void
    @State private var name = ""
    @State private var category = ""
    @State private var description = ""
    @State private var barcode = ""
    @State private var expirationDays = 7
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Product Description", text: $description)
                    TextField("Category", text: $category)
                        .textInputAutocapitalization(.words)
                    HStack(spacing: 8) {
                        TextField("Barcode", text: $barcode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .font(.headline)
                        }
                    }
                }

                Section("Expiration") {
                    Stepper(
                        "Days: \(expirationDays)",
                        value: $expirationDays,
                        in: 0...365
                    )
                }
            }
            .scrollContentBackground(.hidden)
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
                        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(name, category, expirationDays, trimmedBarcode.isEmpty ? nil : trimmedBarcode)
                        isPresented = false
                    }
                    .tint(name.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .accentColor)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .coloredSheet(isPresented: $showScanner) {
                BarcodeScannerSheet { scannedCode in
                    barcode = scannedCode
                }
            }
        }
        .appGradientBackground()
    }
}
