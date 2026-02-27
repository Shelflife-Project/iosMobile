import SwiftUI

struct ShoppingListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.orange.opacity(0.6))

            Text("Shopping List")
                .font(.title)
                .fontWeight(.bold)

            Text("Currently unavailable")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("This feature is coming soon!")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Shopping List")
    }
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
}
