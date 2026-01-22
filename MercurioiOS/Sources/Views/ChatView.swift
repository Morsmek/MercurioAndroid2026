import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    let conversationId: String
    let contactName: String
    let contactId: String

    @State private var messages: [DecryptedMessage] = []
    @State private var messageText = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .tint(.orange)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isSentByMe: message.senderMercurioId == appState.mercurioId,
                                        contactName: contactName
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                    } label: {
                        Image(systemName: "photo")
                            .foregroundColor(.orange)
                    }

                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                        .lineLimit(1...5)

                    Button {
                        Task {
                            await sendMessage()
                        }
                    } label: {
                        if isSending {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(messageText.isEmpty ? .gray : .orange)
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding()
                .background(Color.black.opacity(0.9))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(contactName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Encrypted")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            Task {
                await loadMessages()
            }
        }
    }

    private func loadMessages() async {
        guard let myId = appState.mercurioId else { return }

        isLoading = true

        do {
            let encryptedMessages = try await SupabaseService.shared.fetchMessages(for: conversationId)
            let cryptoService = CryptoService.shared

            var decrypted: [DecryptedMessage] = []

            for msg in encryptedMessages {
                do {
                    let encryptedMsg = EncryptedMessage(
                        encryptedContent: msg.encryptedContent,
                        encryptedAesKey: msg.encryptedAesKey,
                        nonce: msg.nonce,
                        mac: msg.mac
                    )

                    let plaintext = try await cryptoService.decryptMessage(encryptedMsg)

                    decrypted.append(DecryptedMessage(
                        id: msg.id,
                        conversationId: msg.conversationId,
                        senderMercurioId: msg.senderMercurioId,
                        content: plaintext,
                        createdAt: msg.createdAt,
                        readAt: msg.readAt,
                        status: msg.status
                    ))
                } catch {
                    print("Failed to decrypt message: \(error)")
                }
            }

            messages = decrypted
        } catch {
            print("Error loading messages: \(error)")
        }

        isLoading = false
    }

    private func sendMessage() async {
        guard let myId = appState.mercurioId else { return }
        guard !messageText.isEmpty else { return }

        let text = messageText
        messageText = ""
        isSending = true

        do {
            let cryptoService = CryptoService.shared

            guard let recipientUser = try await SupabaseService.shared.fetchUserPublicKeys(mercurioId: contactId) else {
                print("Recipient not found")
                isSending = false
                return
            }

            let recipientRSAKey = RSAPublicKey(
                modulus: recipientUser.rsaPublicKeyModulus,
                exponent: recipientUser.rsaPublicKeyExponent
            )

            let encryptedMsg = try await cryptoService.encryptMessage(text, recipientRSAPublicKey: recipientRSAKey)

            let message = Message(
                conversationId: conversationId,
                senderMercurioId: myId,
                recipientMercurioId: contactId,
                encryptedContent: encryptedMsg.encryptedContent,
                encryptedAesKey: encryptedMsg.encryptedAesKey,
                nonce: encryptedMsg.nonce,
                mac: encryptedMsg.mac
            )

            try await SupabaseService.shared.sendMessage(message)

            let decryptedMsg = DecryptedMessage(
                id: message.id,
                conversationId: message.conversationId,
                senderMercurioId: message.senderMercurioId,
                content: text,
                createdAt: message.createdAt,
                readAt: nil,
                status: .sent
            )

            messages.append(decryptedMsg)
        } catch {
            print("Error sending message: \(error)")
        }

        isSending = false
    }
}

struct MessageBubble: View {
    let message: DecryptedMessage
    let isSentByMe: Bool
    let contactName: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isSentByMe {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(contactName.prefix(1)).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    )
            }

            VStack(alignment: isSentByMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        isSentByMe ?
                        Color.orange.opacity(0.8) :
                        Color.white.opacity(0.1)
                    )
                    .cornerRadius(16)

                HStack(spacing: 4) {
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))

                    if isSentByMe {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                            .foregroundColor(message.status == .read ? .orange : .white.opacity(0.5))
                    }
                }
            }

            if isSentByMe {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: isSentByMe ? .trailing : .leading)
    }

    private var statusIcon: String {
        switch message.status {
        case .sending: return "clock"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
