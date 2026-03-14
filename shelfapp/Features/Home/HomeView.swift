import SwiftUI

struct HomeView: View {
    @Environment(StorageContext.self) private var storageContext
    @Environment(ProductsContext.self) private var productsContext
    @Environment(ShoppingListContext.self) private var shoppingListContext
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext
    @Environment(NotificationsContext.self) private var notificationsContext

    @State private var animateBox = true
    @State private var animateList = true
    @State private var animateCart = true

    private var storages: [Storage] {
        storageContext.storages
    }

    private var totalProducts: Int {
        productsContext.products.count
    }

    private var totalShoppingItems: Int {
        shoppingListContext.items.count
    }

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

                    NavigationLink(destination: ProductsView()) {
                        StatCard(
                            title: "Products",
                            value: "\(totalProducts)",
                            icon: "list.bullet.rectangle",
                            color: .green,
                            animationStyle: .drawOn,
                            isAnimating: animateList
                        )
                    }
                    .buttonStyle(.plain)

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
                Task {
                    await refreshContexts()
                }
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

    private func refreshContexts() async {
        await productsContext.fetch()
        await storageContext.fetch()
        await shoppingListContext.fetchAll(storages: storageContext.storages)
        await notificationsContext.fetchInvites()
        await profileContext.refreshCurrentUser(authContext: authContext)
    }
}

#Preview {
    HomeView()
}
