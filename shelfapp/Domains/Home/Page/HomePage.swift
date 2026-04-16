import SwiftUI
import Observation
import Lottie

@MainActor
@Observable
final class HomePageViewModel {
    var animateBox = true
    var animateList = true
    var animateCart = true

    func triggerStaggeredAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateBox = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateList = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateCart = false }
        }
    }
}

struct HomePage: View {
    @Environment(StorageStore.self) private var storageContext
    @Environment(ProductsStore.self) private var productsContext
    @Environment(ShoppingListStore.self) private var shoppingListContext
    @Environment(ProfileStore.self) private var profileContext
    @Environment(AuthStore.self) private var authContext
    @Environment(NotificationsStore.self) private var notificationsContext

    @State private var viewModel = HomePageViewModel()

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
                    NavigationLink(destination: StoragesPage()) {
                        StatCard(
                            title: "Total Storages",
                            value: "\(storages.count)",
                            icon: "shippingbox.fill",
                            color: .blue,
                            animationStyle: .wiggle,
                            isAnimating: viewModel.animateBox
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: ProductsPage()) {
                        StatCard(
                            title: "Products",
                            value: "\(totalProducts)",
                            icon: "list.bullet.rectangle",
                            color: .green,
                            animationStyle: .drawOn,
                            isAnimating: viewModel.animateList
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: ShoppingListPage()) {
                        StatCard(
                            title: "Shopping List",
                            value: "\(totalShoppingItems)",
                            icon: "cart.fill",
                            color: .orange,
                            animationStyle: .drawOn,
                            isAnimating: viewModel.animateCart
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                LottieView(animation: .named("Inventory")).playing(loopMode: .autoReverse)
            }
            .navigationTitle("Welcome to ShelfLife")
            .appGradientBackground()
            .onAppear {
                viewModel.triggerStaggeredAnimations()
                Task {
                    await refreshContexts()
                }
            }
        }
    }

    private func refreshContexts() async {
        await productsContext.fetch()
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.fetchAll()
        await profileContext.refreshCurrentUser(authContext: authContext)
    }
}

#Preview {
    HomePage()
}
