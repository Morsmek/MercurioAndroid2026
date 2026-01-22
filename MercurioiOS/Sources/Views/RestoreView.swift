import SwiftUI

struct RestoreView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var recoveryPhrase = ""
    @State private var isRestoring = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)

                    Text("Restore Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Enter your 12-word recovery phrase to restore your identity.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recovery Phrase")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextEditor(text: $recoveryPhrase)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Spacer()

                    Button {
                        Task {
                            await restoreIdentity()
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Restore Account")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: recoveryPhrase.isEmpty ? [.gray, .gray] : [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(isRestoring || recoveryPhrase.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .padding(.top, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func restoreIdentity() async {
        isRestoring = true
        errorMessage = nil

        do {
            let cryptoService = CryptoService.shared
            let phrase = recoveryPhrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let id = try await cryptoService.restoreFromPhrase(phrase)

            let publicKeys = try await cryptoService.getPublicKeys()
            let user = User(
                mercurioId: id,
                ed25519PublicKey: publicKeys.ed25519.base64EncodedString(),
                rsaPublicKeyModulus: publicKeys.rsa.modulus,
                rsaPublicKeyExponent: publicKeys.rsa.exponent,
                createdAt: Date(),
                lastSeen: Date(),
                isOnline: true
            )

            try await SupabaseService.shared.uploadUserPublicKeys(user: user)

            appState.setIdentity(mercurioId: id)
        } catch {
            errorMessage = "Failed to restore account: \(error.localizedDescription)"
        }

        isRestoring = false
    }
}
