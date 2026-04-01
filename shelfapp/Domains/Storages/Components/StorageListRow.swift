import SwiftUI

struct StorageListRow: View {
    var storage: Storage
    var isOwner: Bool

    @State private var animateIcon = true

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isOwner ? .blue : .purple)
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
                        .foregroundStyle(.cyan)
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(storage.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 12) {
                    Label(
                        "\(storage.items.count) items",
                        systemImage: "list.bullet"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !isOwner, let ownerName = storage.owner?.username {
                        Label(ownerName, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if storage.shoppingItems.count > 0 {
                Text("\(storage.shoppingItems.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.red))
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) { animateIcon = false }
            }
        }
    }
}
