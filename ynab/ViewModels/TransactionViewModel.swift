import Foundation
import FirebaseFirestore

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var categories:   [Category]   = []
    @Published private(set) var settings:     UserSettings  = UserSettings()
    @Published private(set) var budgets:      [Budget]      = []
    @Published private(set) var recurringTransactions: [RecurringTransaction] = []
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
        let budListener = service.listenBudgets(userId: userId) { [weak self] list in
            self?.budgets = list
        }
        let recListener = service.listenRecurringTransactions(userId: userId) { [weak self] list in
            self?.recurringTransactions = list
        }
        listeners = [txListener, catListener, setListener, budListener, recListener]
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

    func updateCategory(_ updated: Category) async {
        try? await service.updateCategory(updated)
    }

    /// Returns false if category is in use — same rule as Flutter version
    func deleteCategory(id: String) async -> Bool {
        if transactions.contains(where: { $0.categoryId == id }) { return false }
        try? await service.deleteCategory(id: id)
        return true
    }

    // MARK: — Budgets CRUD

    func addBudget(userId: String, categoryId: String, limitAmount: Double) async {
        let b = Budget(id: "", userId: userId, categoryId: categoryId, limitAmount: limitAmount)
        try? await service.addBudget(b)
    }

    func updateBudget(_ updated: Budget) async {
        try? await service.updateBudget(updated)
    }

    func deleteBudget(id: String) async {
        try? await service.deleteBudget(id: id)
    }

    // MARK: — Recurring Transactions CRUD

    func addRecurringTransaction(userId: String, amount: Double, type: TransactionType, categoryId: String, frequency: RecurringFrequency, startDate: Date, note: String?) async {
        let r = RecurringTransaction(id: "", userId: userId, amount: amount, type: type, categoryId: categoryId, frequency: frequency, startDate: startDate, note: note)
        try? await service.addRecurringTransaction(r)
    }

    func updateRecurringTransaction(_ updated: RecurringTransaction) async {
        try? await service.updateRecurringTransaction(updated)
    }

    func deleteRecurringTransaction(id: String) async {
        try? await service.deleteRecurringTransaction(id: id)
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
    
    func budgetProgress(for categoryId: String, month: Date) -> (spent: Double, limit: Double)? {
        guard let budget = budgets.first(where: { $0.categoryId == categoryId }) else { return nil }
        let expenses = forMonth(month).filter { $0.categoryId == categoryId && $0.type == .expense }
        let spent = expenses.reduce(0) { $0 + $1.amount }
        return (spent, budget.limitAmount)
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
