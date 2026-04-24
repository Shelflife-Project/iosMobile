import SwiftUI

struct StorageListRow: View {
    var storage: Storage
    var isOwner: Bool

    @State private var animateIcon = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isOwner ? Color.appPrimary : Color.appAccentFresh)
                    .symbolEffect(.drawOn, isActive: animateIcon)

                if isOwner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.wiggle, isActive: animateIcon)
                        .offset(x: 4, y: 4)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appSecondaryLabel)
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(storage.name)
                    .font(AppFont.bodyEmphasized())

                HStack(spacing: Spacing.md) {
                    Label("\(storage.itemCount) items", systemImage: "list.bullet")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appSecondaryLabel)

                    if !isOwner, let ownerName = storage.owner?.username {
                        Label(ownerName, systemImage: "person")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.appSecondaryLabel)
                    }
                }
            }

            Spacer()

            if storage.shoppingItemCount > 0 {
                Text("\(storage.shoppingItemCount)")
                    .font(AppFont.caption2())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Capsule().fill(Color.appAccentWarm))
            }
        }
        .padding(.vertical, Spacing.sm)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) { animateIcon = false }
            }
        }
    }
}
