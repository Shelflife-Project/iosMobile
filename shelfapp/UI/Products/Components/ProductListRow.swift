import SwiftUI

struct ProductListRow: View {
    var product: Product

    @State private var isDrawing = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            RemoteImage(
                url: product.serverId.flatMap { ResourceURLBuilder.productIconURL(productId: $0) },
                placeholder: "shippingbox",
                size: 40
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(product.name)
                    .font(AppFont.bodyEmphasized())

                HStack {
                    if !product.category.isEmpty {
                        Label {
                            Text(product.category)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.appSecondaryLabel)
                        } icon: {
                            Image(systemName: "tag.circle")
                                .foregroundStyle(Color.appAccentFresh)
                                .symbolEffect(.drawOn, isActive: isDrawing)
                        }
                    } else {
                        Label {
                            Text("No category")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.appSecondaryLabel)
                        } icon: {
                            Image(systemName: "tag.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.appDestructive)
                                .symbolEffect(.drawOn, isActive: isDrawing)
                        }
                    }
                    Spacer()
                    Label {
                        Text("\(product.expirationDaysDelta)d")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.appSecondaryLabel)
                    } icon: {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color.appPrimary)
                    }
                }
                .onAppear { isDrawing = false }
            }
        }
        .padding(.vertical, Spacing.sm)
        .listCardBackground(accent: .appAccentFresh)
    }
}
