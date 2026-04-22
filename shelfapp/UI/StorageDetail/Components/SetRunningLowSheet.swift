import SwiftUI

struct SetRunningLowSheet: View {
    let product: Product
    let existingSetting: RunningLowSetting?
    @Binding var isPresented: Bool
    var onSave: (Int) -> Void
    var onRemove: (() -> Void)?

    @State private var threshold: Int

    init(
        product: Product,
        existingSetting: RunningLowSetting?,
        isPresented: Binding<Bool>,
        onSave: @escaping (Int) -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.product = product
        self.existingSetting = existingSetting
        self._isPresented = isPresented
        self.onSave = onSave
        self.onRemove = onRemove
        _threshold = State(initialValue: existingSetting?.threshold ?? 2)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                        Text(product.name)
                            .fontWeight(.semibold)
                    }
                    .frame(height: 36)
                }

                Section {
                    Stepper("Alert when below \(threshold)", value: $threshold, in: 1...100)
                } header: {
                    Text("Running Low Threshold")
                } footer: {
                    Text("You'll be notified when this product falls to \(threshold) or fewer items in this storage.")
                        .font(.caption)
                }

                if existingSetting != nil, let onRemove = onRemove {
                    Section {
                        Button(role: .destructive) {
                            onRemove()
                            isPresented = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Remove Running Low Alert")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existingSetting == nil ? "Set Running Low" : "Edit Running Low")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(threshold)
                        isPresented = false
                    }
                }
            }
        }
        .appGradientBackground()
    }
}
