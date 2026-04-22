import SwiftUI
import Lottie

struct HomePage: View {
    @Environment(StorageService.self) private var storageContext
    @Environment(ProductService.self) private var productsContext
    @Environment(ShoppingListService.self) private var shoppingListContext
    @Environment(ProfileService.self) private var profileContext
    @Environment(AuthService.self) private var authContext
    @Environment(NotificationsService.self) private var notificationsContext

    @State private var pageModel = HomePageModel()

    // MARK: - Derived stats

    private var storages: [Storage] { storageContext.storages }
    private var totalProducts: Int { productsContext.products.count }
    private var totalShoppingItems: Int { shoppingListContext.items.count }

    var body: some View {
        mainContent
            .navigationTitle("Welcome to ShelfLife")
            .appGradientBackground()
            .refreshable { await refreshContexts() }
            .onAppear { pageModel.triggerStaggeredAnimations() }
            .task { await refreshContexts() }
    }

    // MARK: - Sections

    private var mainContent: some View {
        VStack(spacing: Spacing.xl) {
            subtitle
            statCards
            LottieView(animation: .named("Inventory")).playing(loopMode: .autoReverse)
        }
    }

    private var subtitle: some View {
        Text("Your personal inventory management system")
            .font(AppFont.body())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.base)
    }

    private var statCards: some View {
        VStack(spacing: Spacing.base) {
            NavigationLink(destination: StoragesPage()) {
                StatCard(
                    title: "Total Storages",
                    value: "\(storages.count)",
                    icon: "shippingbox.fill",
                    color: .blue,
                    animationStyle: .wiggle,
                    isAnimating: pageModel.animateBox
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
                    isAnimating: pageModel.animateList
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
                    isAnimating: pageModel.animateCart
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.base)
    }

    private func refreshContexts() async {
        await productsContext.fetch()
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.fetchAll()
        await profileContext.refreshCurrentUser()
    }
}

// MARK: - PageModel

@MainActor
@Observable
final class HomePageModel {
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

#Preview("Home — Light") {
    HomePage()
        .environment(AppEnvironment.preview().storages)
        .environment(AppEnvironment.preview().products)
        .environment(AppEnvironment.preview().shoppingList)
        .environment(AppEnvironment.preview().profile)
        .environment(AppEnvironment.preview().auth)
        .environment(AppEnvironment.preview().notifications)
        .preferredColorScheme(.light)
}

#Preview("Home — Dark") {
    HomePage()
        .environment(AppEnvironment.preview().storages)
        .environment(AppEnvironment.preview().products)
        .environment(AppEnvironment.preview().shoppingList)
        .environment(AppEnvironment.preview().profile)
        .environment(AppEnvironment.preview().auth)
        .environment(AppEnvironment.preview().notifications)
        .preferredColorScheme(.dark)
}
