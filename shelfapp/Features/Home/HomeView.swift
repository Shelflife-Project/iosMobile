import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @Query var storages: [Storage]

    @State private var animateBox = true
    @State private var animateList = true
    @State private var animateCart = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your personal inventory management system")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    NavigationLink(destination: StoragesView()) {
                        StatCard(
                            title: "Total Storages",
                            value: "\(storages.count)",
                            icon: "shippingbox.fill",
                            color: .blue,
                            animationStyle: .wiggle,
                            isAnimating: animateBox
                        )
                    }
                    .buttonStyle(.plain)

                    let totalItems = storages.reduce(0) { $0 + $1.items.count }
                    NavigationLink(destination: ProductsView()) {
                        StatCard(
                            title: "Items",
                            value: "\(totalItems)",
                            icon: "list.bullet.rectangle",
                            color: .green,
                            animationStyle: .drawOn,
                            isAnimating: animateList
                        )
                    }
                    .buttonStyle(.plain)

                    let totalShoppingItems = storages.reduce(0) { $0 + $1.shoppingItems.count }
                    NavigationLink(destination: ShoppingListView()) {
                        StatCard(
                            title: "Shopping List",
                            value: "\(totalShoppingItems)",
                            icon: "cart.fill",
                            color: .orange,
                            animationStyle: .drawOn,
                            isAnimating: animateCart
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Welcome to ShelfLife")
            .appGradientBackground()
            .onAppear {
                triggerStaggeredAnimations()
            }
        }
    }

    private func triggerStaggeredAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.6)) { animateBox = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) { animateList = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) { animateCart = false }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
