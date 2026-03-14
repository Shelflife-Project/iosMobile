import SwiftUI
import PhotosUI

struct EditAccountSheet: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext

    let user: User
    @Binding var isPresented: Bool
    let onSaved: () -> Void

    @State private var username: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false

    init(user: User, isPresented: Binding<Bool>, onSaved: @escaping () -> Void) {
        self.user = user
        self._isPresented = isPresented
        self.onSaved = onSaved
        _username = State(initialValue: user.username)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Username") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Profile Picture") {
                    HStack {
                        Text("Current")
                        Spacer()
                        RemoteImage(
                            url: APIService.shared.userPfpURL(userId: user.serverId ?? 0),
                            placeholder: "person.crop.circle",
                            size: 44
                        )
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Upload New Picture", systemImage: "photo")
                    }

                    if selectedImageData != nil {
                        Text("New image selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaveDisabled || isSaving)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    await loadSelectedPhoto(newValue)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { profileContext.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        profileContext.errorMessage = nil
                    }
                }
            )) {
                Button("OK") { profileContext.errorMessage = nil }
            } message: {
                Text(profileContext.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    private var isSaveDisabled: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            selectedImageData = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpegData = image.jpegData(compressionQuality: 0.85) else {
                return
            }
            selectedImageData = jpegData
        } catch {
            profileContext.errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        guard let userId = user.serverId else { return }

        isSaving = true
        defer { isSaving = false }

        let didSave = await profileContext.updateAccount(
            userId: userId,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            profileImageData: selectedImageData,
            authContext: authContext
        )

        if didSave {
            onSaved()
            isPresented = false
        }
    }
}
