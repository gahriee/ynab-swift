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
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap {
                    Transaction.fromDict($0.documentID, $0.data())
                }.sorted(by: { $0.date > $1.date }) ?? []
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

    func updateCategory(_ c: Category) async throws {
        try await db.collection("categories").document(c.id).updateData(c.toDict())
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

    // MARK: — Budgets

    func listenBudgets(
        userId: String,
        onChange: @escaping ([Budget]) -> Void
    ) -> ListenerRegistration {
        db.collection("budgets")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap {
                    Budget.fromDict($0.documentID, $0.data())
                } ?? []
                onChange(items)
            }
    }

    func addBudget(_ b: Budget) async throws {
        try await db.collection("budgets").addDocument(data: b.toDict())
    }

    func updateBudget(_ b: Budget) async throws {
        try await db.collection("budgets").document(b.id).updateData(b.toDict())
    }

    func deleteBudget(id: String) async throws {
        try await db.collection("budgets").document(id).delete()
    }

    // MARK: — Recurring Transactions

    func listenRecurringTransactions(
        userId: String,
        onChange: @escaping ([RecurringTransaction]) -> Void
    ) -> ListenerRegistration {
        db.collection("recurring_transactions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap {
                    RecurringTransaction.fromDict($0.documentID, $0.data())
                } ?? []
                onChange(items)
            }
    }

    func addRecurringTransaction(_ r: RecurringTransaction) async throws {
        try await db.collection("recurring_transactions").addDocument(data: r.toDict())
    }

    func updateRecurringTransaction(_ r: RecurringTransaction) async throws {
        try await db.collection("recurring_transactions").document(r.id).updateData(r.toDict())
    }

    func deleteRecurringTransaction(id: String) async throws {
        try await db.collection("recurring_transactions").document(id).delete()
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
        let budSnap = try await db.collection("budgets").whereField("userId", isEqualTo: userId).getDocuments()
        let recSnap = try await db.collection("recurring_transactions").whereField("userId", isEqualTo: userId).getDocuments()
        for doc in txSnap.documents  { batch.deleteDocument(doc.reference) }
        for doc in catSnap.documents { batch.deleteDocument(doc.reference) }
        for doc in budSnap.documents { batch.deleteDocument(doc.reference) }
        for doc in recSnap.documents { batch.deleteDocument(doc.reference) }
        try await batch.commit()
        try await seedCategories(userId: userId)
    }
}
