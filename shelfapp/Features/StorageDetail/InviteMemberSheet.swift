import SwiftUI

struct InviteMemberSheet: View {
    @Binding var isPresented: Bool
    var onInvite: (String) -> Void
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite by Email") {
                    TextField("Email address", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }

                Section {
                    Text("The user will receive an invitation they can accept or decline.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invite") {
                        onInvite(email)
                        isPresented = false
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@"))
                }
            }
        }
        .appGradientBackground()
    }
}
