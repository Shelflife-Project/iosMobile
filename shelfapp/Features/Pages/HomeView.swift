import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @Query var storages: [Storage]

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
                    StatCard(
                        title: "Total Storages",
                        value: "\(storages.count)",
                        icon: "cube.box.fill",
                        color: .blue
                    )

                    let totalItems = storages.reduce(0) { $0 + $1.items.count }
                    StatCard(
                        title: "Items",
                        value: "\(totalItems)",
                        icon: "list.bullet",
                        color: .green
                    )

                    let totalShoppingItems = storages.reduce(0) { $0 + $1.shoppingItems.count }
                    StatCard(
                        title: "Shopping List",
                        value: "\(totalShoppingItems)",
                        icon: "cart.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: StoragesView()) {
                        HStack {
                            Image(systemName: "cube.box")
                            Text("View Storages")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                    }

                    NavigationLink(destination: ProductsView()) {
                        HStack {
                            Image(systemName: "cube")
                            Text("View Products")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Home")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
