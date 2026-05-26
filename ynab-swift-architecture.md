# YNAB — Swift / SwiftUI Architecture

**App:** YNAB · **Platform:** macOS 13 (Ventura)+ · **Language:** Swift 5.9 · **UI:** SwiftUI · **Pattern:** MVVM

> ✅ Native macOS app. Firebase-backed — data syncs across devices.
> ✅ Swift Language Version: **5.9** · Deployment Target: **macOS 13.0** · Compatible with Ventura 13.6.1

---

## Philosophy

> If SwiftUI can do it, we don't add a package for it.

| Concern          | Uses                                          | Built-in?              |
| ---------------- | --------------------------------------------- | ---------------------- |
| State management | `ObservableObject` + `@Published`             | ✅ Yes                 |
| Navigation       | `TabView` + `NavigationStack`                 | ✅ Yes                 |
| Models           | Plain Swift structs                           | ✅ Yes                 |
| UI icons         | SF Symbols via `Image(systemName:)`           | ✅ Yes                 |
| Charts           | `Charts` framework (macOS 13+)                | ✅ Yes                 |
| Auth + Database  | Firebase iOS SDK                              | ❌ External (required) |

**Total added packages: 1** — `firebase-ios-sdk` (includes Auth + Firestore). Via Swift Package Manager. **No CocoaPods needed.**

> ⚠️ **Swift 5.9 note:** `@Observable` macro and `SwiftData` require macOS 14+. This architecture uses `ObservableObject` + `@Published` which is fully supported on macOS 13+.

---

## 1. Features

| #   | Feature      | Description                                                   |
| --- | ------------ | ------------------------------------------------------------- |
| 1   | Dashboard    | Total balance, income vs expense summary, recent transactions |
| 2   | Transactions | Add, edit, delete income and expense entries                  |
| 3   | Categories   | Simple labels for grouping transactions                       |
| 4   | Reports      | Monthly spending breakdown by category                        |
| 5   | Settings     | Currency symbol, theme, clear data                            |
| 6   | Budgets      | Monthly spending limits per category with progress bars       |
| 7   | Wallets      | Multiple accounts (e.g., Cash, Bank) with separate balances   |
| 8   | Export       | Export transaction history to CSV format                      |
| 9   | Recurring    | Automatic recurring transactions (daily, weekly, monthly)     |

---

## 2. Project Structure

```
YNAB/
├── YNABApp.swift                        # @main entry point + auth gate
│
├── App/
│   └── AppTheme.swift                   # AppColors, Color extensions
│
├── Models/
│   └── Models.swift                     # All data structs and enums
│
├── Services/
│   ├── AuthService.swift                # Firebase Auth wrapper
│   └── TransactionService.swift         # Firestore CRUD + listeners
│
├── ViewModels/
│   ├── AuthViewModel.swift              # ObservableObject — auth state
│   └── TransactionViewModel.swift       # ObservableObject — all data logic
│
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift
│   ├── Main/
│   │   └── MainView.swift               # TabView shell
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Transactions/
│   │   ├── TransactionListView.swift
│   │   └── AddTransactionView.swift
│   ├── Reports/
│   │   └── ReportsView.swift
│   ├── Budgets/
│   │   ├── BudgetListView.swift
│   │   └── AddBudgetView.swift
│   ├── Recurring/
│   │   ├── RecurringListView.swift
│   │   └── AddRecurringView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── CategoryListView.swift
│
└── Components/
    ├── BalanceCard.swift
    ├── TransactionRow.swift
    ├── AmountText.swift
    ├── EmptyStateView.swift
    └── CategoryIcon.swift
```

---

## 3. Data Models (`Models/Models.swift`)

Plain Swift structs — no code generation, no annotations. Uses `Codable`-style manual `fromDict`/`toDict` for Firestore compatibility.

```swift
import Foundation

// MARK: - Transaction

struct Transaction: Identifiable, Equatable {
    let id: String
    let userId: String          // links to Firebase Auth UID
    let amount: Double
    let type: TransactionType
    let categoryId: String
    let date: Date
    let note: String?

    init(
        id: String,
        userId: String,
        amount: Double,
        type: TransactionType,
        categoryId: String,
        date: Date,
        note: String? = nil
    ) {
        self.id         = id
        self.userId     = userId
        self.amount     = amount
        self.type       = type
        self.categoryId = categoryId
        self.date       = date
        self.note       = note
    }

    // Firestore → Swift
    static func fromDict(_ id: String, _ dict: [String: Any]) -> Transaction? {
        guard
            let userId     = dict["userId"]     as? String,
            let amount     = (dict["amount"]    as? NSNumber)?.doubleValue,
            let typeRaw    = dict["type"]       as? String,
            let type       = TransactionType(rawValue: typeRaw),
            let categoryId = dict["categoryId"] as? String,
            let timestamp  = dict["date"]       as? Timestamp
        else { return nil }

        return Transaction(
            id:         id,
            userId:     userId,
            amount:     amount,
            type:       type,
            categoryId: categoryId,
            date:       timestamp.dateValue(),
            note:       dict["note"] as? String
        )
    }

    // Swift → Firestore
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "userId":     userId,
            "amount":     amount,
            "type":       type.rawValue,
            "categoryId": categoryId,
            "date":       Timestamp(date: date),
        ]
        if let note = note { dict["note"] = note }
        return dict
    }
}

// MARK: - Category

struct Category: Identifiable, Equatable {
    let id: String
    let userId: String          // links to Firebase Auth UID
    let name: String
    let icon: String            // SF Symbol name
    let type: TransactionType

    static func fromDict(_ id: String, _ dict: [String: Any]) -> Category? {
        guard
            let userId  = dict["userId"] as? String,
            let name    = dict["name"]   as? String,
            let icon    = dict["icon"]   as? String,
            let typeRaw = dict["type"]   as? String,
            let type    = TransactionType(rawValue: typeRaw)
        else { return nil }

        return Category(id: id, userId: userId, name: name, icon: icon, type: type)
    }

    func toDict() -> [String: Any] {
        ["userId": userId, "name": name, "icon": icon, "type": type.rawValue]
    }
}

// MARK: - UserSettings

struct UserSettings: Equatable {
    var currencySymbol: String
    var themeMode: AppThemeMode

    init(currencySymbol: String = "PHP", themeMode: AppThemeMode = .system) {
        self.currencySymbol = currencySymbol
        self.themeMode      = themeMode
    }

    static func fromDict(_ dict: [String: Any]) -> UserSettings {
        UserSettings(
            currencySymbol: dict["currencySymbol"] as? String ?? "PHP",
            themeMode: AppThemeMode(rawValue: dict["themeMode"] as? String ?? "system") ?? .system
        )
    }

    func toDict() -> [String: Any] {
        ["currencySymbol": currencySymbol, "themeMode": themeMode.rawValue]
    }

    func copyWith(currencySymbol: String? = nil, themeMode: AppThemeMode? = nil) -> UserSettings {
        UserSettings(
            currencySymbol: currencySymbol ?? self.currencySymbol,
            themeMode:      themeMode      ?? self.themeMode
        )
    }
}

// MARK: - Enums

enum TransactionType: String, CaseIterable {
    case income  = "income"
    case expense = "expense"

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .income:  return AppColors.income
        case .expense: return AppColors.expense
        }
    }

    var sign: String {
        switch self {
        case .income:  return "+"
        case .expense: return "-"
        }
    }
}

enum AppThemeMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
```

---

## 4. Services

### `Services/AuthService.swift`

```swift
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
```

### `Services/TransactionService.swift`

```swift
import FirebaseFirestore

// Firestore Timestamp import
typealias Timestamp = FirebaseFirestore.Timestamp

final class TransactionService {
    private let db = Firestore.firestore()

    // MARK: — Transactions

    /// Attaches a real-time listener. Returns a handle to remove it later.
    func listenTransactions(
        userId: String,
        onChange: @escaping ([Transaction]) -> Void
    ) -> ListenerRegistration {
        db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap {
                    Transaction.fromDict($0.documentID, $0.data())
                } ?? []
                onChange(items)
            }
    }

    func addTransaction(_ t: Transaction) async throws {
        try await db.collection("transactions").addDocument(data: t.toDict())
    }

    func updateTransaction(_ t: Transaction) async throws {
        try await db.collection("transactions").document(t.id).updateData(t.toDict())
    }

    func deleteTransaction(id: String) async throws {
        try await db.collection("transactions").document(id).delete()
    }

    // MARK: — Categories

    func listenCategories(
        userId: String,
        onChange: @escaping ([Category]) -> Void
    ) -> ListenerRegistration {
        db.collection("categories")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap {
                    Category.fromDict($0.documentID, $0.data())
                } ?? []
                onChange(items)
            }
    }

    func addCategory(_ c: Category) async throws {
        try await db.collection("categories").addDocument(data: c.toDict())
    }

    func deleteCategory(id: String) async throws {
        try await db.collection("categories").document(id).delete()
    }

    func seedCategories(userId: String) async throws {
        let seeds: [(String, String, TransactionType)] = [
            ("Food",          "fork.knife",            .expense),
            ("Transport",     "bus",                   .expense),
            ("Housing",       "house",                 .expense),
            ("Entertainment", "gamecontroller",         .expense),
            ("Shopping",      "bag",                   .expense),
            ("Others",        "ellipsis.circle",        .expense),
            ("Salary",        "briefcase",             .income),
            ("Freelance",     "laptopcomputer",         .income),
            ("Gift",          "gift",                  .income),
            ("Others",        "dollarsign.circle",      .income),
        ]
        let batch = db.batch()
        for (name, icon, type) in seeds {
            let ref = db.collection("categories").document()
            let cat = Category(id: ref.documentID, userId: userId,
                               name: name, icon: icon, type: type)
            batch.setData(cat.toDict(), forDocument: ref)
        }
        try await batch.commit()
    }

    // MARK: — Settings

    func listenSettings(
        userId: String,
        onChange: @escaping (UserSettings) -> Void
    ) -> ListenerRegistration {
        db.collection("settings").document(userId)
            .addSnapshotListener { snapshot, _ in
                let settings = snapshot?.exists == true
                    ? UserSettings.fromDict(snapshot!.data() ?? [:])
                    : UserSettings()
                onChange(settings)
            }
    }

    func updateSettings(userId: String, settings: UserSettings) async throws {
        try await db.collection("settings").document(userId).setData(settings.toDict())
    }

    func clearAllData(userId: String) async throws {
        let batch = db.batch()
        let txSnap  = try await db.collection("transactions").whereField("userId", isEqualTo: userId).getDocuments()
        let catSnap = try await db.collection("categories").whereField("userId", isEqualTo: userId).getDocuments()
        for doc in txSnap.documents  { batch.deleteDocument(doc.reference) }
        for doc in catSnap.documents { batch.deleteDocument(doc.reference) }
        try await batch.commit()
        try await seedCategories(userId: userId)
    }
}
```

---

## 5. State Management

**No third-party state library.** SwiftUI's built-in `ObservableObject` + `@Published` + `@EnvironmentObject`.

> Flutter `ChangeNotifier` → Swift `ObservableObject`
> Flutter `notifyListeners()` → automatic via `@Published`
> Flutter `ListenableBuilder` → SwiftUI's automatic view invalidation via `@EnvironmentObject`

### `ViewModels/AuthViewModel.swift`

```swift
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
```

### `ViewModels/TransactionViewModel.swift`

```swift
import Foundation
import FirebaseFirestore

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var categories:   [Category]   = []
    @Published private(set) var settings:     UserSettings  = UserSettings()
    @Published var isLoading: Bool  = false
    @Published var error: String?   = nil

    private let service = TransactionService()
    private var listeners: [ListenerRegistration] = []

    // MARK: — Computed properties (replaces Flutter getters)

    var totalIncome:  Double { sum(.income)  }
    var totalExpense: Double { sum(.expense) }
    var balance:      Double { totalIncome - totalExpense }

    var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    // MARK: — Listen (replaces Flutter's .listen(userId))

    /// Call once on login. Attaches all Firestore listeners.
    func startListening(userId: String) {
        isLoading = true
        stopListening()  // remove stale listeners if any

        let txListener = service.listenTransactions(userId: userId) { [weak self] list in
            self?.transactions = list
            self?.isLoading    = false
        }
        let catListener = service.listenCategories(userId: userId) { [weak self] list in
            guard let self else { return }
            if list.isEmpty {
                Task { try? await self.service.seedCategories(userId: userId) }
            }
            self.categories = list
        }
        let setListener = service.listenSettings(userId: userId) { [weak self] s in
            self?.settings = s
        }
        listeners = [txListener, catListener, setListener]
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    // MARK: — Transaction CRUD

    func addTransaction(
        userId: String,
        amount: Double,
        type: TransactionType,
        categoryId: String,
        date: Date,
        note: String? = nil
    ) async {
        let t = Transaction(id: "", userId: userId, amount: amount,
                            type: type, categoryId: categoryId, date: date, note: note)
        try? await service.addTransaction(t)
    }

    func updateTransaction(_ updated: Transaction) async {
        try? await service.updateTransaction(updated)
    }

    func deleteTransaction(id: String) async {
        try? await service.deleteTransaction(id: id)
    }

    // MARK: — Category CRUD

    func addCategory(userId: String, name: String, icon: String, type: TransactionType) async {
        let c = Category(id: "", userId: userId, name: name, icon: icon, type: type)
        try? await service.addCategory(c)
    }

    /// Returns false if category is in use — same rule as Flutter version
    func deleteCategory(id: String) async -> Bool {
        if transactions.contains(where: { $0.categoryId == id }) { return false }
        try? await service.deleteCategory(id: id)
        return true
    }

    // MARK: — Settings

    func updateSettings(userId: String, updated: UserSettings) async {
        try? await service.updateSettings(userId: userId, settings: updated)
    }

    func clearAllData(userId: String) async {
        try? await service.clearAllData(userId: userId)
    }

    // MARK: — Reports helpers

    struct MonthTotals {
        let income:  Double
        let expense: Double
    }

    func totals(for month: Date) -> MonthTotals {
        let filtered = forMonth(month)
        return MonthTotals(
            income:  filtered.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount },
            expense: filtered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        )
    }

    func breakdown(for month: Date) -> [(Category, Double)] {
        let expenses = forMonth(month).filter { $0.type == .expense }
        var map = [String: Double]()
        for t in expenses { map[t.categoryId, default: 0] += t.amount }
        return map.compactMap { (catId, total) in
            let cat = categories.first(where: { $0.id == catId })
                ?? Category(id: catId, userId: "", name: "Unknown", icon: "questionmark", type: .expense)
            return (cat, total)
        }.sorted { $0.1 > $1.1 }
    }

    // MARK: — Private helpers

    private func sum(_ type: TransactionType) -> Double {
        transactions.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }

    private func forMonth(_ date: Date) -> [Transaction] {
        let cal = Calendar.current
        return transactions.filter {
            cal.component(.year,  from: $0.date) == cal.component(.year,  from: date) &&
            cal.component(.month, from: $0.date) == cal.component(.month, from: date)
        }
    }
}
```

### Wiring in `YNABApp.swift`

```swift
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
```

---

## 6. Navigation Flow

```
AuthView (Login / Register)
  └── on login → MainView

MainView (TabView)
  ├── Tab 1: DashboardView
  │     └── toolbar button → sheet → AddTransactionView
  │
  ├── Tab 2: TransactionListView
  │     ├── Picker (segmented): All · Income · Expense
  │     ├── tap row → sheet → AddTransactionView (edit mode)
  │     ├── swipeActions → delete (with undo via .overlay toast)
  │     └── toolbar button → AddTransactionView
  │
  ├── Tab 3: ReportsView
  │     └── Month picker (prev/next buttons) + category breakdown
  │
  ├── Tab 4: BudgetListView
  │     └── Monthly limits vs spending progress
  │
  ├── Tab 5: RecurringListView
  │     └── Scheduled transactions management
  │
  └── Tab 6: SettingsView
        └── NavigationLink → CategoryListView
```

---

## 7. Views

### UI Design Language

All views use **native macOS/SwiftUI aesthetics** — SF Symbols, system materials, and standard SwiftUI controls.

| Flutter Element         | SwiftUI Equivalent                                         |
| ----------------------- | ---------------------------------------------------------- |
| `CupertinoIcons`        | `Image(systemName:)` — SF Symbols                          |
| `BottomNavigationBar`   | `TabView` with `.tabItem`                                  |
| `Navigator.push`        | `NavigationStack` + `NavigationLink`                       |
| `showModalBottomSheet`  | `.sheet(isPresented:)`                                     |
| `SegmentedButton`       | `Picker(.segmented)`                                       |
| `Dismissible` swipe     | `.swipeActions`                                            |
| `SnackBar`              | custom `.overlay` toast or `@State var showAlert`          |
| `showDialog`            | `.alert` or `.confirmationDialog`                          |
| `LinearProgressIndicator` | `ProgressView(value:total:)`                             |
| `FloatingActionButton`  | `.toolbar { ToolbarItem }` or overlay `Button`             |
| `showDatePicker()`      | `DatePicker`                                               |
| `ChangeNotifier` listen | `@EnvironmentObject` / `@ObservedObject`                   |

### `Views/Auth/AuthView.swift`

```swift
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email    = ""
    @State private var password = ""
    @State private var isLogin  = true  // toggles between Login and Register

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle")
                .font(.system(size: 64))
                .foregroundColor(AppColors.primary)

            Text(isLogin ? "Sign In" : "Create Account")
                .font(.title2).fontWeight(.semibold)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            if let error = authVM.error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            Button(isLogin ? "Sign In" : "Create Account") {
                Task {
                    if isLogin {
                        await authVM.login(email: email, password: password)
                    } else {
                        await authVM.register(email: email, password: password)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(authVM.isLoading)

            if authVM.isLoading { ProgressView() }

            Button(isLogin ? "Don't have an account? Register" : "Already have an account? Sign in") {
                isLogin.toggle()
                authVM.error = nil
            }
            .buttonStyle(.plain)
            .foregroundColor(AppColors.primary)
        }
        .padding(40)
        .frame(width: 360)
    }
}
```

### `Views/Main/MainView.swift`

```swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house") }
                .tag(0)

            TransactionListView()
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
                .tag(1)

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
```

### `Views/Dashboard/DashboardView.swift`

```swift
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var authVM:        AuthViewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Balance card
                    BalanceCard(
                        balance:        transactionVM.balance,
                        income:         transactionVM.totalIncome,
                        expense:        transactionVM.totalExpense,
                        currencySymbol: transactionVM.settings.currencySymbol
                    )

                    // Recent transactions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent").font(.headline)
                        if transactionVM.recentTransactions.isEmpty {
                            EmptyStateView(message: "No transactions yet")
                        } else {
                            ForEach(transactionVM.recentTransactions) { tx in
                                TransactionRow(
                                    transaction:    tx,
                                    category:       transactionVM.categories.first { $0.id == tx.categoryId },
                                    currencySymbol: transactionVM.settings.currencySymbol
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(userId: authVM.currentUser?.uid ?? "")
            }
        }
    }
}
```

### `Views/Transactions/TransactionListView.swift`

```swift
import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var authVM:        AuthViewModel
    @State private var filter:       TransactionFilter = .all
    @State private var showAddSheet  = false
    @State private var editingTx:    Transaction?

    enum TransactionFilter: String, CaseIterable {
        case all = "All", income = "Income", expense = "Expense"
    }

    private var filtered: [Transaction] {
        switch filter {
        case .all:     return transactionVM.transactions
        case .income:  return transactionVM.transactions.filter { $0.type == .income }
        case .expense: return transactionVM.transactions.filter { $0.type == .expense }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented filter — mirrors Flutter's SegmentedButton
                Picker("Filter", selection: $filter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(filtered) { tx in
                        TransactionRow(
                            transaction:    tx,
                            category:       transactionVM.categories.first { $0.id == tx.categoryId },
                            currencySymbol: transactionVM.settings.currencySymbol
                        )
                        .onTapGesture { editingTx = tx }
                        // Swipe-to-delete — replaces Flutter's Dismissible
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await transactionVM.deleteTransaction(id: tx.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(userId: authVM.currentUser?.uid ?? "")
            }
            .sheet(item: $editingTx) { tx in
                AddTransactionView(userId: authVM.currentUser?.uid ?? "", editing: tx)
            }
        }
    }
}
```

### `Views/Transactions/AddTransactionView.swift`

```swift
import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @Environment(\.dismiss) private var dismiss

    let userId:  String
    var editing: Transaction? = nil   // nil = add mode, non-nil = edit mode

    @State private var amountText  = ""
    @State private var type:         TransactionType = .expense
    @State private var categoryId  = ""
    @State private var date        = Date()
    @State private var note        = ""

    private var filteredCategories: [Category] {
        transactionVM.categories.filter { $0.type == type }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text(editing == nil ? "Add Transaction" : "Edit Transaction")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await save(); dismiss() }
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(amountText.isEmpty || categoryId.isEmpty)
            }
            .padding()

            Divider()

            Form {
                // Amount with currency prefix
                Section("Amount") {
                    HStack {
                        Text(transactionVM.settings.currencySymbol)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountText)
                    }
                }

                // Income / Expense toggle
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _ in categoryId = "" }
                }

                // Category dropdown — filtered by type
                Section("Category") {
                    Picker("Category", selection: $categoryId) {
                        Text("Select…").tag("")
                        ForEach(filteredCategories) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(cat.id)
                        }
                    }
                }

                // Date picker
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                // Optional note
                Section("Note (optional)") {
                    TextField("Add a note…", text: $note)
                }
            }
        }
        .frame(width: 400, height: 480)
        .onAppear {
            if let tx = editing {
                amountText = String(format: "%.2f", tx.amount)
                type       = tx.type
                categoryId = tx.categoryId
                date       = tx.date
                note       = tx.note ?? ""
            }
        }
    }

    private func save() async {
        guard let amount = Double(amountText) else { return }
        if let tx = editing {
            await transactionVM.updateTransaction(
                Transaction(id: tx.id, userId: userId, amount: amount,
                            type: type, categoryId: categoryId, date: date,
                            note: note.isEmpty ? nil : note)
            )
        } else {
            await transactionVM.addTransaction(
                userId: userId, amount: amount, type: type,
                categoryId: categoryId, date: date, note: note.isEmpty ? nil : note
            )
        }
    }
}
```

### `Views/Reports/ReportsView.swift`

```swift
import SwiftUI
import Charts    // macOS 13+ built-in — replaces Flutter manual progress bars

struct ReportsView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @State private var selectedMonth = Date()

    private var totals: TransactionViewModel.MonthTotals {
        transactionVM.totals(for: selectedMonth)
    }
    private var breakdown: [(Category, Double)] {
        transactionVM.breakdown(for: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Month navigator
                    HStack {
                        Button { stepMonth(-1) } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(selectedMonth, format: .dateTime.month(.wide).year())
                            .font(.headline)
                            .frame(minWidth: 160)
                        Button { stepMonth(1) } label: {
                            Image(systemName: "chevron.right")
                        }
                    }

                    // Totals strip
                    HStack(spacing: 24) {
                        VStack {
                            Text("Income").foregroundColor(.secondary).font(.caption)
                            AmountText(
                                amount: totals.income, type: .income,
                                currencySymbol: transactionVM.settings.currencySymbol
                            )
                        }
                        VStack {
                            Text("Expense").foregroundColor(.secondary).font(.caption)
                            AmountText(
                                amount: totals.expense, type: .expense,
                                currencySymbol: transactionVM.settings.currencySymbol
                            )
                        }
                    }

                    // Category breakdown with progress bars
                    if breakdown.isEmpty {
                        EmptyStateView(message: "No expenses this month")
                    } else {
                        ForEach(breakdown, id: \.0.id) { (cat, amount) in
                            HStack {
                                CategoryIcon(icon: cat.icon)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cat.name).font(.subheadline)
                                    ProgressView(
                                        value: amount,
                                        total: max(totals.expense, 1)
                                    )
                                    .tint(AppColors.expense)
                                }
                                Spacer()
                                Text("\(transactionVM.settings.currencySymbol)\(String(format: "%.2f", amount))")
                                    .font(.subheadline).monospacedDigit()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }

    private func stepMonth(_ delta: Int) {
        selectedMonth = Calendar.current.date(
            byAdding: .month, value: delta, to: selectedMonth
        ) ?? selectedMonth
    }
}
```

### `Views/Settings/SettingsView.swift`

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @State private var currencyInput  = ""
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Currency
                Section("Currency") {
                    TextField("Symbol (e.g. PHP, $, €)", text: $currencyInput)
                        .onAppear { currencyInput = transactionVM.settings.currencySymbol }
                        .onSubmit { saveSettings() }
                }

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { transactionVM.settings.themeMode },
                        set: { newMode in
                            Task {
                                await transactionVM.updateSettings(
                                    userId: authVM.currentUser?.uid ?? "",
                                    updated: transactionVM.settings.copyWith(themeMode: newMode)
                                )
                            }
                        }
                    )) {
                        ForEach(AppThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Account
                Section("Account") {
                    if let email = authVM.currentUser?.email {
                        LabeledContent("Signed in as", value: email)
                    }
                    Button(role: .destructive) { authVM.logout() } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // Data
                Section("Data") {
                    NavigationLink("Manage Categories") {
                        CategoryListView()
                    }
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    Task {
                        await transactionVM.clearAllData(userId: authVM.currentUser?.uid ?? "")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all transactions and reset categories. This cannot be undone.")
            }
        }
    }

    private func saveSettings() {
        Task {
            await transactionVM.updateSettings(
                userId: authVM.currentUser?.uid ?? "",
                updated: transactionVM.settings.copyWith(currencySymbol: currencyInput)
            )
        }
    }
}
```

### `Views/Settings/CategoryListView.swift`

```swift
import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel

    @State private var showAddForm = false
    @State private var newName   = ""
    @State private var newIcon   = "tag"
    @State private var newType:    TransactionType = .expense
    @State private var errorMsg: String?

    var body: some View {
        List {
            ForEach(transactionVM.categories) { cat in
                HStack {
                    CategoryIcon(icon: cat.icon)
                    Text(cat.name)
                    Spacer()
                    Text(cat.type.label)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(cat.type.color.opacity(0.15))
                        .foregroundColor(cat.type.color)
                        .cornerRadius(6)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            let ok = await transactionVM.deleteCategory(id: cat.id)
                            if !ok { errorMsg = "Reassign or delete transactions first" }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddForm) {
            VStack(spacing: 16) {
                Text("New Category").font(.headline)
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                TextField("SF Symbol name", text: $newIcon)
                    .textFieldStyle(.roundedBorder)
                Picker("Type", selection: $newType) {
                    ForEach(TransactionType.allCases, id: \.self) { t in
                        Text(t.label).tag(t)
                    }
                }.pickerStyle(.segmented)
                HStack {
                    Button("Cancel") { showAddForm = false }
                    Spacer()
                    Button("Add") {
                        Task {
                            await transactionVM.addCategory(
                                userId: authVM.currentUser?.uid ?? "",
                                name: newName, icon: newIcon, type: newType
                            )
                            showAddForm = false
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(AppColors.primary)
                    .disabled(newName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
        .alert("Cannot delete", isPresented: .constant(errorMsg != nil), actions: {
            Button("OK") { errorMsg = nil }
        }, message: { Text(errorMsg ?? "") })
    }
}
```

---

## 8. Components

### `Components/BalanceCard.swift`

```swift
import SwiftUI

struct BalanceCard: View {
    let balance:        Double
    let income:         Double
    let expense:        Double
    let currencySymbol: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Text("\(currencySymbol)\(String(format: "%.2f", balance))")
                .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                .monospacedDigit()

            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Label("Income", systemImage: "arrow.down.circle.fill")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                    Text("\(currencySymbol)\(String(format: "%.2f", income))")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Label("Expense", systemImage: "arrow.up.circle.fill")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                    Text("\(currencySymbol)\(String(format: "%.2f", expense))")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .monospacedDigit()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.primary)
        .cornerRadius(16)
    }
}
```

### `Components/AmountText.swift`

```swift
import SwiftUI

/// Always use this view for any monetary amount — never hardcode colors in screens.
struct AmountText: View {
    let amount:         Double
    let type:           TransactionType
    let currencySymbol: String
    var font: Font = .body

    var body: some View {
        Text("\(type.sign)\(currencySymbol)\(String(format: "%.2f", amount))")
            .font(font)
            .fontWeight(.semibold)
            .foregroundColor(type.color)
            .monospacedDigit()
    }
}
```

### `Components/TransactionRow.swift`

```swift
import SwiftUI

struct TransactionRow: View {
    let transaction:    Transaction
    let category:       Category?
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(icon: category?.icon ?? "questionmark")
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Unknown")
                    .font(.subheadline).fontWeight(.medium)
                if let note = transaction.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundColor(.secondary)
                }
                Text(transaction.date, style: .date)
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            AmountText(amount: transaction.amount, type: transaction.type,
                       currencySymbol: currencySymbol)
        }
        .padding(.vertical, 4)
    }
}
```

### `Components/CategoryIcon.swift`

```swift
import SwiftUI

struct CategoryIcon: View {
    let icon: String
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(AppColors.primary.opacity(0.12))
            .foregroundColor(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

### `Components/EmptyStateView.swift`

```swift
import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
```

---

## 9. Theme (`App/AppTheme.swift`)

```swift
import SwiftUI

enum AppColors {
    // Brand
    static let primary     = Color(hex: "EA580C")  // Orange 600

    // Semantic
    static let income      = Color(hex: "16A34A")  // Green 600
    static let expense     = Color(hex: "DC2626")  // Red 600
    static let warning     = Color(hex: "D97706")  // Amber 600

    // Dark mode variants are handled automatically via
    // Color(nsColor: .windowBackgroundColor) or custom asset catalog entries
}

// Hex color initializer — Swift 5.9 compatible
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255
        g = Double((int >>  8) & 0xFF) / 255
        b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

> **Dark mode:** SwiftUI automatically adapts system colors. For custom colors, add a Color Set in the asset catalog with Light/Dark variants, or use the `.colorScheme` environment value to switch manually.

---

## 10. Key Operations

| Operation          | Swift call                                                               |
| ------------------ | ------------------------------------------------------------------------ |
| Register           | `await authVM.register(email:password:)`                                 |
| Login              | `await authVM.login(email:password:)`                                    |
| Logout             | `authVM.logout()`                                                        |
| Stream data        | `transactionVM.startListening(userId:)` — called once on login           |
| Add transaction    | `await transactionVM.addTransaction(userId:amount:type:categoryId:date:note:)` |
| Edit transaction   | `await transactionVM.updateTransaction(_:)`                              |
| Delete transaction | `await transactionVM.deleteTransaction(id:)`                             |
| Add category       | `await transactionVM.addCategory(userId:name:icon:type:)`                |
| Delete category    | `await transactionVM.deleteCategory(id:)` → `false` if in use            |
| Monthly totals     | `transactionVM.totals(for: month)` → `MonthTotals`                      |
| Category breakdown | `transactionVM.breakdown(for: month)` → `[(Category, Double)]`           |
| Update settings    | `await transactionVM.updateSettings(userId:updated:)`                    |
| Clear all data     | `await transactionVM.clearAllData(userId:)`                              |

---

## 11. Persistence & Backend

**Same Firebase schema as Flutter version — fully compatible.**

```
/transactions/{transactionId}
  userId:     String    ← links to Firebase Auth UID
  amount:     Double
  type:       String    ← "income" | "expense"
  categoryId: String
  date:       Timestamp ← used for sort order
  note:       String?   ← optional

/categories/{categoryId}
  userId: String
  name:   String
  icon:   String        ← SF Symbol name (e.g. "fork.knife")
  type:   String        ← "income" | "expense"

/settings/{userId}
  currencySymbol: String
  themeMode:      String ← "system" | "light" | "dark"
```

> **Note on icons:** Flutter version stores emoji (e.g. `🍔`). Swift version stores SF Symbol names (e.g. `"fork.knife"`). If migrating data from the Flutter app, run a one-time migration to convert emoji → SF Symbol names.

**Firestore Security Rules** — identical to Flutter version, no changes needed.

---

## 12. Deletion Rules

```
Delete Transaction  →  removed immediately from Firestore, no cascade

Delete Category
  └── blocked if any transaction references it
  └── transactionVM.deleteCategory() returns false
  └── view shows Alert: "Reassign or delete transactions first"
```

---

## 13. Color Scheme Reference

| Token          | Light Mode   | Dark Mode    | Usage                         |
| -------------- | ------------ | ------------ | ----------------------------- |
| primary        | `#EA580C`    | `#FB923C`    | Buttons, active icons, accent |
| income         | `#16A34A`    | `#4ADE80`    | Income amounts                |
| expense        | `#DC2626`    | `#F87171`    | Expense amounts               |
| warning        | `#D97706`    | `#FBBF24`    | Budget warnings               |

> System colors (`Color.primary`, `Color.secondary`, `Color(nsColor:.windowBackgroundColor)`) handle background/text automatically for light/dark.

---

## 14. Module Responsibilities

| Module                           | Responsibility                                                          |
| -------------------------------- | ----------------------------------------------------------------------- |
| `Models/Models.swift`            | Plain Swift structs — `fromDict`, `toDict`, `copyWith`. No logic.       |
| `Services/AuthService.swift`     | Firebase Auth wrapper only — no business logic.                         |
| `Services/TransactionService.swift` | Firestore CRUD + listeners — no business logic.                      |
| `ViewModels/AuthViewModel.swift` | `ObservableObject` — auth state, loading, error.                        |
| `ViewModels/TransactionViewModel.swift` | `ObservableObject` — all transaction/category/settings operations and report calculations. |
| `Views/`                         | Presentation only. Reads viewmodel via `@EnvironmentObject`, calls viewmodel methods. |
| `Components/`                    | Reusable UI pieces with no viewmodel dependency.                        |

---

## 15. Swift Package Dependencies

Add via **Xcode → File → Add Package Dependencies** (no CocoaPods needed):

```
https://github.com/firebase/firebase-ios-sdk
```

Select these products:
- `FirebaseAuth`
- `FirebaseFirestore`

**That's it. 1 package, 2 products.**

---

## 16. System Requirements

| Tool            | Version                  |
| --------------- | ------------------------ |
| Swift           | **5.9**                  |
| Xcode           | 15.0 (bundled Swift 5.9) |
| macOS (dev)     | **13.6.1 Ventura** ✅    |
| macOS (target)  | 13.0+ (Ventura and later)|

### Project Settings Checklist (Xcode)

To ensure Swift 5.9 and macOS 13 compatibility:

1. **Target → General → Minimum Deployments** → set to `macOS 13.0`
2. **Build Settings → Swift Language Version** → set to `Swift 5`
   - (Xcode 15 with Swift 5.9 toolchain uses Swift 5 language mode)
3. **Build Settings → MACOSX_DEPLOYMENT_TARGET** → `13.0`
4. Add a `.swift-version` file at project root:
   ```
   5.9
   ```

### macOS App Entitlements

Add these to your `.entitlements` file for Firebase/network access:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

---

## 17. Setup Steps

```bash
# 1. Create macOS app project in Xcode
#    File → New → Project → macOS → App
#    Interface: SwiftUI, Language: Swift
#    Set bundle ID, e.g. com.yourname.ynab

# 2. Set deployment target to macOS 13.0 in project settings

# 3. Add Firebase SDK via Swift Package Manager
#    File → Add Package Dependencies
#    URL: https://github.com/firebase/firebase-ios-sdk
#    Add: FirebaseAuth, FirebaseFirestore

# 4. Configure Firebase
#    - Go to console.firebase.google.com
#    - Create/open project → Add app → macOS
#    - Download GoogleService-Info.plist
#    - Drag it into Xcode project root (check "Copy if needed")

# 5. Add network entitlement
#    Target → Signing & Capabilities → App Sandbox
#    Check: Outgoing Connections (Client)

# 6. Build and run
#    Cmd + R
```

### `.gitignore` — Key Entries

```
GoogleService-Info.plist
*.xcuserstate
.build/
DerivedData/
xcuserdata/
```

---

## 18. Flutter → Swift Conversion Reference

| Flutter / Dart                          | Swift / SwiftUI                                    |
| --------------------------------------- | -------------------------------------------------- |
| `ChangeNotifier` + `notifyListeners()`  | `ObservableObject` + `@Published`                  |
| `ListenableBuilder`                     | `@EnvironmentObject` (auto-refresh)                |
| `StatefulWidget` + `setState`           | `@State` + SwiftUI auto-refresh                    |
| `StreamBuilder<T>`                      | `.task` + `async/await` or Firestore listener      |
| `Navigator.push`                        | `NavigationStack` + `NavigationLink`               |
| `showModalBottomSheet`                  | `.sheet(isPresented:)`                             |
| `showDialog`                            | `.alert` / `.confirmationDialog`                   |
| `SnackBar`                              | custom toast overlay or `.alert`                   |
| `SegmentedButton`                       | `Picker(.segmented)`                               |
| `Dismissible` swipe-to-delete           | `.swipeActions`                                    |
| `LinearProgressIndicator`               | `ProgressView(value:total:)`                       |
| `FloatingActionButton`                  | `ToolbarItem(.primaryAction)` or overlay `Button`  |
| `showDatePicker()`                      | `DatePicker`                                       |
| `Text.copyWith(style)`                  | `.font()` + `.fontWeight()` + `.foregroundColor()` |
| `Color(0xFFEA580C)`                     | `Color(hex: "EA580C")`                             |
| `CupertinoIcons.*`                      | `Image(systemName: "sf.symbol.name")`              |
| `pubspec.yaml` packages                 | Swift Package Manager                              |
| `pod install`                           | Not needed (SPM handles everything)                |
