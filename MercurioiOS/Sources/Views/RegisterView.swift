import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var isGenerating = false
    @State private var showRecoveryPhrase = false
    @State private var recoveryPhrase = ""
    @State private var mercurioId = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                if !showRecoveryPhrase {
                    Spacer()

                    Image(systemName: "key.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)

                    Text("Create Your Identity")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Your identity will be created locally on your device. You'll receive a 12-word recovery phrase to backup your account.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Button {
                        Task {
                            await generateIdentity()
                        }
                    } label: {
                        if isGenerating {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Generate Identity")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(isGenerating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                } else {
                    RecoveryPhraseView(
                        recoveryPhrase: recoveryPhrase,
                        mercurioId: mercurioId,
                        onContinue: {
                            appState.setIdentity(mercurioId: mercurioId)
                        }
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateIdentity() async {
        isGenerating = true
        errorMessage = nil

        do {
            let cryptoService = CryptoService.shared
            let id = try await cryptoService.generateIdentity()

            if let phrase = await cryptoService.getRecoveryPhrase() {
                mercurioId = id
                recoveryPhrase = phrase

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

                showRecoveryPhrase = true
            }
        } catch {
            errorMessage = "Failed to generate identity: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
