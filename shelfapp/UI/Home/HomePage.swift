import SwiftUI
import Lottie

struct HomePage: View {
    @Environment(StorageService.self) private var storageContext
    @Environment(ProductService.self) private var productsContext
    @Environment(ShoppingListService.self) private var shoppingListContext
    @Environment(ProfileService.self) private var profileContext
    @Environment(AuthService.self) private var authContext
    @Environment(NotificationsService.self) private var notificationsContext

    @State private var appearance = StaggeredAppearance(slots: 3)

    // MARK: - Derived stats

    private var storages: [Storage] { storageContext.storages }
    private var totalProducts: Int { productsContext.products.count }
    private var totalShoppingItems: Int { shoppingListContext.items.count }

    var body: some View {
        mainContent
            .navigationTitle("Welcome to ShelfLife")
            .appGradientBackground()
            .refreshable { await refreshContexts() }
            .onAppear { appearance.trigger() }
            .task { await refreshContexts() }
    }

    // MARK: - Sections

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                subtitle
                statCards
                lottieSection
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.hidden)
    }

    private var subtitle: some View {
        Text("Your household inventory, at a glance")
            .font(AppFont.callout())
            .foregroundStyle(Color.appSecondaryLabel)
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
                    accent: .storages,
                    animationStyle: .wiggle,
                    isAnimating: appearance.isAnimating(0)
                )
            }
            .buttonStyle(TappableCardStyle())

            NavigationLink(destination: ProductsPage()) {
                StatCard(
                    title: "Products",
                    value: "\(totalProducts)",
                    icon: "list.bullet.rectangle.fill",
                    accent: .products,
                    animationStyle: .drawOn,
                    isAnimating: appearance.isAnimating(1)
                )
            }
            .buttonStyle(TappableCardStyle())

            NavigationLink(destination: ShoppingListPage()) {
                StatCard(
                    title: "Shopping List",
                    value: "\(totalShoppingItems)",
                    icon: "cart.fill",
                    accent: .shopping,
                    animationStyle: .bounce,
                    isAnimating: appearance.isAnimating(2)
                )
            }
            .buttonStyle(TappableCardStyle())
        }
        .padding(.horizontal, Spacing.base)
    }

    private var lottieSection: some View {
        LottieView(animation: .named("Inventory"))
            .playing(loopMode: .autoReverse)
            .frame(maxHeight: 220)
            .padding(.top, Spacing.sm)
    }

    private func refreshContexts() async {
        await productsContext.fetch()
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.fetchAll()
        await profileContext.refreshCurrentUser()
    }
}

// MARK: - TappableCardStyle

/// Button style for tap-anywhere cards: scales + haptic on press, no tint change.
struct TappableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.tap() }
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
