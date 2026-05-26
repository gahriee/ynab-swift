import Foundation
import SwiftUI
import FirebaseFirestore

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

// MARK: - Budget

struct Budget: Identifiable, Equatable {
    let id: String
    let userId: String
    let categoryId: String
    let limitAmount: Double

    static func fromDict(_ id: String, _ dict: [String: Any]) -> Budget? {
        guard
            let userId      = dict["userId"] as? String,
            let categoryId  = dict["categoryId"] as? String,
            let limitAmount = (dict["limitAmount"] as? NSNumber)?.doubleValue
        else { return nil }

        return Budget(id: id, userId: userId, categoryId: categoryId, limitAmount: limitAmount)
    }

    func toDict() -> [String: Any] {
        [
            "userId": userId,
            "categoryId": categoryId,
            "limitAmount": limitAmount
        ]
    }
}

// MARK: - RecurringTransaction

enum RecurringFrequency: String, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    
    var label: String { rawValue.capitalized }
}

struct RecurringTransaction: Identifiable, Equatable {
    let id: String
    let userId: String
    let amount: Double
    let type: TransactionType
    let categoryId: String
    let frequency: RecurringFrequency
    let startDate: Date
    let note: String?

    static func fromDict(_ id: String, _ dict: [String: Any]) -> RecurringTransaction? {
        guard
            let userId     = dict["userId"] as? String,
            let amount     = (dict["amount"] as? NSNumber)?.doubleValue,
            let typeRaw    = dict["type"] as? String,
            let type       = TransactionType(rawValue: typeRaw),
            let categoryId = dict["categoryId"] as? String,
            let freqRaw    = dict["frequency"] as? String,
            let frequency  = RecurringFrequency(rawValue: freqRaw),
            let timestamp  = dict["startDate"] as? Timestamp
        else { return nil }

        return RecurringTransaction(
            id: id,
            userId: userId,
            amount: amount,
            type: type,
            categoryId: categoryId,
            frequency: frequency,
            startDate: timestamp.dateValue(),
            note: dict["note"] as? String
        )
    }

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "type": type.rawValue,
            "categoryId": categoryId,
            "frequency": frequency.rawValue,
            "startDate": Timestamp(date: startDate)
        ]
        if let note = note { dict["note"] = note }
        return dict
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
