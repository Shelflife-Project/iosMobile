import SwiftUI
import PhotosUI

struct EditAccountSheet: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext

    let user: User
    @Binding var isPresented: Bool
    @Binding var profileImageRefreshToken: String
    var onSaved: (() -> Void)? = nil

    @State private var username: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false

    init(user: User, isPresented: Binding<Bool>, profileImageRefreshToken: Binding<String>, onSaved: (() -> Void)? = nil) {
        self.user = user
        self._isPresented = isPresented
        self._profileImageRefreshToken = profileImageRefreshToken
        self.onSaved = onSaved
        _username = State(initialValue: user.username)
    }

    private var userPfpURL: URL? {
        guard let userId = user.serverId else {
            return nil
        }
        guard let baseURL = APIService.shared.userPfpURL(userId: userId) else {
            return nil
        }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "v", value: profileImageRefreshToken)]
        return components?.url
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
                        if let selectedImageData,
                           let selectedImage = UIImage(data: selectedImageData) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        } else {
                            RemoteImage(
                                url: userPfpURL,
                                placeholder: "person.crop.circle",
                                size: 44
                            )
                        }
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
            .scrollContentBackground(.hidden)
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
        .appGradientBackground()
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
            profileImageRefreshToken = UUID().uuidString
            onSaved?()
            isPresented = false
        }
    }
}
