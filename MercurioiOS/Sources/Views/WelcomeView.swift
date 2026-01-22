import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToRegister = false
    @State private var navigateToRestore = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()

                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 25, x: 0, y: 3)

                        Text("Welcome to Mercurio")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)

                        Text("Private messaging that requires no personal information. Ever.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 16) {
                            FeatureRow(icon: "nosign", text: "No personal info")
                            FeatureRow(icon: "lock.fill", text: "End-to-end encrypted")
                            FeatureRow(icon: "eye.slash.fill", text: "Anonymous identity")
                        }
                        .padding(.vertical)

                        Spacer()

                        VStack(spacing: 16) {
                            Button {
                                navigateToRegister = true
                            } label: {
                                Text("Create New Account")
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

                            Button {
                                navigateToRestore = true
                            } label: {
                                Text("Restore from Phrase")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $navigateToRestore) {
                RestoreView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
