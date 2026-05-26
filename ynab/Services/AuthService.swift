import FirebaseAuth

final class AuthService {
    private let auth = Auth.auth()

    var currentUser: User? { auth.currentUser }

    // Listener-based auth state — converted to async stream via continuation
    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in handler(user) }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }

    func register(email: String, password: String) async throws {
        try await auth.createUser(withEmail: email, password: password)
    }

    func login(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func logout() throws {
        try auth.signOut()
    }
}
