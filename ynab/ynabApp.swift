import SwiftUI
import FirebaseCore

@main
struct YNABApp: App {
    @StateObject private var authVM        = AuthViewModel()
    @StateObject private var transactionVM = TransactionViewModel()

    init() {
        FirebaseApp.configure()     // replaces Firebase.initializeApp() in Flutter
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(transactionVM)
                // Apply color scheme from user settings
                .preferredColorScheme(transactionVM.settings.themeMode.colorScheme)
        }
    }
}

// Auth gate — replaces Flutter's StreamBuilder<User?>
struct RootView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel

    var body: some View {
        Group {
            if authVM.currentUser != nil {
                MainView()
                    .onAppear {
                        transactionVM.startListening(userId: authVM.currentUser!.uid)
                    }
                    .onDisappear {
                        transactionVM.stopListening()
                    }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authVM.currentUser?.uid)
    }
}
