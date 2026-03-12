import SwiftUI

struct ProductListRow: View {
    var product: Product

    @State private var isDrawing = true

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(
                url: product.serverId.flatMap { APIService.shared.productIconURL(productId: $0) },
                placeholder: "shippingbox",
                size: 40
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack {
                    if !product.category.isEmpty {
                        Label {
                            Text(product.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "tag.circle")
                                .foregroundStyle(.yellow)
                                .symbolEffect(.drawOn, isActive: isDrawing)
                        }
                    } else {
                        Label {
                            Text("Without category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "tag.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.red)
                                .symbolEffect(.drawOn, isActive: isDrawing)
                        }
                    }
                    Spacer()
                    Label {
                        Text("\(product.expirationDaysDelta)d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.purple)
                    }
                }
                .onAppear {
                    isDrawing = false
                }
            }
        }
        .padding(.vertical, 4)
    }
}
