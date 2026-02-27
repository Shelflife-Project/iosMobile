import SwiftUI
import SwiftData

// MARK: - HomeView

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @Query var storages: [Storage]

    // Animation states – staggered: box → list → cart
    @State private var animateBox = true
    @State private var animateList = true
    @State private var animateCart = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome to Shelf Life")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your personal inventory management system")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    // 1) Storages – shippingbox.fill wiggle
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

                    // 2) Products – list.bullet.rectangle drawOn
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

                    // 3) Shopping List – cart.fill drawOn
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
            .navigationTitle("Home")
            .appGradientBackground()
            .onAppear {
                triggerStaggeredAnimations()
            }
        }
    }

    /// Fires animations in sequence: box → list → cart
    private func triggerStaggeredAnimations() {
        
        // Step 1: box wiggle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateBox = false
            }
        }

        // Step 2: list draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateList = false
            }
        }

        // Step 3: cart draws
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateCart = false
            }
        }
    }
}

// MARK: - StatCard

enum StatCardAnimation {
    case wiggle
    case drawOn
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var animationStyle: StatCardAnimation = .drawOn
    var isAnimating: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(8)
                .modifier(StatCardAnimationModifier(
                    style: animationStyle,
                    isAnimating: isAnimating
                ))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.85))
        .cornerRadius(12)
    }
}

struct StatCardAnimationModifier: ViewModifier {
    let style: StatCardAnimation
    let isAnimating: Bool

    func body(content: Content) -> some View {
        switch style {
        case .wiggle:
            content
                .symbolEffect(.wiggle, isActive: isAnimating)
        case .drawOn:
            content
                .symbolEffect(.drawOn, isActive: isAnimating)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
