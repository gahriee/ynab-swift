import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool   = false
    @Published var error: String?    = nil
    @Published var currentUser: User? = nil

    private let service = AuthService()
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Replaces Flutter's authStateChanges stream
        listenerHandle = service.addAuthStateListener { [weak self] user in
            self?.currentUser = user
        }
    }

    deinit {
        if let handle = listenerHandle {
            service.removeAuthStateListener(handle)
        }
    }

    func login(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            try await service.login(email: email, password: password)
        } catch let err as NSError {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func register(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            try await service.register(email: email, password: password)
        } catch let err as NSError {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        try? service.logout()
    }
}
