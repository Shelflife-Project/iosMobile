import SwiftUI

struct NotificationsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.gray)
                Text("No Notifications")
                    .font(.headline)
                Text("You're all caught up!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationTitle("Notifications")
        }
    }
}

#Preview {
    NotificationsView()
}
