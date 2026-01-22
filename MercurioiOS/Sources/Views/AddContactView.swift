import SwiftUI
import AVFoundation

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var mercurioId = ""
    @State private var displayName = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    @State private var showScanner = false

    let onContactAdded: () async -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "person.badge.plus.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)

                    Text("Add Contact")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mercurio ID")
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack {
                            TextField("05...", text: $mercurioId)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)

                            Button {
                                showScanner = true
                            } label: {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("e.g., John from work", text: $displayName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .autocapitalization(.words)
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
                            await addContact()
                        }
                    } label: {
                        if isAdding {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Add Contact")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: canAdd ? [.orange, .yellow] : [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(isAdding || !canAdd)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .padding(.top, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            QRScannerView(scannedCode: $mercurioId)
        }
    }

    private var canAdd: Bool {
        !mercurioId.isEmpty && !displayName.isEmpty
    }

    private func addContact() async {
        guard let myId = appState.mercurioId else { return }

        isAdding = true
        errorMessage = nil

        do {
            if !isValidMercurioId(mercurioId) {
                errorMessage = "Invalid Mercurio ID format"
                isAdding = false
                return
            }

            let _ = try await SupabaseService.shared.fetchUserPublicKeys(mercurioId: mercurioId)

            let contact = Contact(
                userMercurioId: myId,
                contactMercurioId: mercurioId,
                displayName: displayName
            )

            try await SupabaseService.shared.addContact(contact)

            await onContactAdded()
            dismiss()
        } catch {
            errorMessage = "Failed to add contact: \(error.localizedDescription)"
        }

        isAdding = false
    }

    private func isValidMercurioId(_ id: String) -> Bool {
        return id.count == 66 && id.hasPrefix("05")
    }
}

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scannedCode: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text("Scan QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()

                Text("Position the QR code within the frame")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.orange)
                .padding()
            }
        }
    }
}
