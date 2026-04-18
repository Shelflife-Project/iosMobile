import SwiftUI

struct EditProductSheet: View {
    let product: Product
    @Binding var isPresented: Bool
    var onSave: (String, String, Int, String?) -> Void

    @State private var name: String
    @State private var category: String
    @State private var expirationDays: Int
    @State private var barcode: String
    @State private var showScanner = false

    init(product: Product, isPresented: Binding<Bool>, onSave: @escaping (String, String, Int, String?) -> Void) {
        self.product = product
        self._isPresented = isPresented
        self.onSave = onSave

        _name = State(initialValue: product.name)
        _category = State(initialValue: product.category)
        _expirationDays = State(initialValue: product.expirationDaysDelta)
        _barcode = State(initialValue: product.barcode ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                        .textInputAutocapitalization(.words)
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
                        in: 1...365
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Product")
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
                    .tint(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
