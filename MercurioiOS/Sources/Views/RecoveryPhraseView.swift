import SwiftUI

struct RecoveryPhraseView: View {
    let recoveryPhrase: String
    let mercurioId: String
    let onContinue: () -> Void

    @State private var isCopied = false
    @State private var showWarning = true

    private var words: [String] {
        recoveryPhrase.components(separatedBy: " ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.orange)

                Text("Recovery Phrase")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if showWarning {
                    VStack(spacing: 12) {
                        Text("⚠️ Write down these words")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("This is the ONLY way to recover your account. Store it safely and never share it with anyone.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 24, alignment: .trailing)

                            Text(word)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                Button {
                    UIPasteboard.general.string = recoveryPhrase
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy to Clipboard")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                }
                .padding()

                Text("Your Mercurio ID")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(mercurioId)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button {
                    onContinue()
                } label: {
                    Text("I've Saved My Recovery Phrase")
                        .font(.headline)
                        .foregroundColor(.black)
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Color.black)
    }
}
