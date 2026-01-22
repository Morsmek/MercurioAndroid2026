import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var contacts: [Contact]
    @State private var showMercurioId = false
    @State private var showRecoveryPhrase = false
    @State private var showQRCode = false
    @State private var showLogoutAlert = false
    @State private var mercurioId: String?
    @State private var recoveryPhrase: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 20)

                        Text("Mercurio User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if let id = mercurioId {
                            Text("\(id.prefix(16))...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.top, 20)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(spacing: 0) {
                        SettingsRow(icon: "qrcode", title: "Show My QR Code", subtitle: "Let others scan to add you") {
                            showQRCode = true
                        }

                        SettingsRow(icon: "key", title: "Your Mercurio ID", subtitle: "View and share your Mercurio ID") {
                            showMercurioId = true
                        }

                        SettingsRow(icon: "shield", title: "Recovery Phrase", subtitle: "View your 12-word recovery phrase") {
                            showRecoveryPhrase = true
                        }

                        SettingsRow(icon: "lock", title: "Privacy & Security", subtitle: "App lock, biometric settings") {
                        }

                        SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage notification preferences") {
                        }

                        SettingsRow(icon: "info.circle", title: "About Mercurio", subtitle: "Version 1.0.0") {
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeView()
        }
        .alert("Your Mercurio ID", isPresented: $showMercurioId) {
            Button("Close", role: .cancel) {}
        } message: {
            if let id = mercurioId {
                Text(id)
            }
        }
        .alert("Recovery Phrase", isPresented: $showRecoveryPhrase) {
            Button("Close", role: .cancel) {}
        } message: {
            if let phrase = recoveryPhrase {
                Text(phrase)
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                Task {
                    await logout()
                }
            }
        } message: {
            Text("Are you sure you want to logout? Make sure you have your recovery phrase saved.")
        }
        .onAppear {
            Task {
                await loadUserData()
            }
        }
    }

    private func loadUserData() async {
        let cryptoService = CryptoService.shared
        mercurioId = await cryptoService.getMercurioId()
        recoveryPhrase = await cryptoService.getRecoveryPhrase()
    }

    private func logout() async {
        do {
            try await CryptoService.shared.clearAllKeys()
            appState.clearIdentity()
        } catch {
            print("Logout error: \(error)")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct QRCodeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var qrImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()

                Text("Your QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                } else {
                    ProgressView()
                        .tint(.orange)
                }

                Text("Scan this code to add me as a contact")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            generateQRCode()
        }
    }

    private func generateQRCode() {
        guard let mercurioId = appState.mercurioId else { return }

        let data = mercurioId.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")

        if let outputImage = filter?.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }
}
