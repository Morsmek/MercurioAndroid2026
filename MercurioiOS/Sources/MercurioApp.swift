import SwiftUI

@main
struct MercurioApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoading {
                SplashView()
            } else if appState.hasIdentity {
                HomeView()
                    .environmentObject(appState)
            } else {
                WelcomeView()
                    .environmentObject(appState)
            }
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var hasIdentity = false
    @Published var mercurioId: String?

    init() {
        Task {
            await checkIdentity()
        }
    }

    func checkIdentity() async {
        do {
            let cryptoService = CryptoService.shared
            hasIdentity = await cryptoService.hasIdentity()
            if hasIdentity {
                mercurioId = await cryptoService.getMercurioId()
            }
            isLoading = false
        } catch {
            print("Error checking identity: \(error)")
            isLoading = false
        }
    }

    func setIdentity(mercurioId: String) {
        self.mercurioId = mercurioId
        self.hasIdentity = true
    }

    func clearIdentity() {
        self.mercurioId = nil
        self.hasIdentity = false
    }
}
