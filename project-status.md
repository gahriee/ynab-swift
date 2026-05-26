# YNAB — Swift / SwiftUI Project Status

**App:** YNAB  
**Platform:** macOS 13 (Ventura)+  
**Language:** Swift 5.9  
**UI:** SwiftUI  
**Pattern:** MVVM  

## Phase 1: Core Setup & Architecture (Windows-Friendly)
- [x] Scaffold project directory structure (`YNAB`, `App`, `Models`, `Services`, `ViewModels`, `Views`, `Components`)
- [x] Setup Data Models (`Models.swift` for `Transaction`, `Category`, `UserSettings`)
- [x] Setup Theme (`AppTheme.swift` with custom colors)
- [x] Setup App Entry Point (`YNABApp.swift`)

## Phase 2: Firebase Services
- [x] Implement `AuthService` (Login, Register, Logout, State Listener)
- [x] Implement `TransactionService` (CRUD for Transactions, Categories, Settings)

## Phase 3: State Management (ViewModels)
- [x] Implement `AuthViewModel`
- [x] Implement `TransactionViewModel` (Transactions, Categories, Settings state and operations)

## Phase 4: Core UI & Components
- [x] Implement `AuthView`
- [x] Implement `MainView` (TabView shell)
- [x] Build Components (`BalanceCard`, `TransactionRow`, `AmountText`, `EmptyStateView`, `CategoryIcon`)

## Phase 5: Features implementation
- [x] **Dashboard:** Total balance, income vs expense summary, recent transactions.
- [x] **Transactions:** List view, Add/Edit/Delete actions.
- [x] **Reports:** Monthly spending breakdown with Charts.
- [x] **Settings:** Currency symbol, Theme switcher, Clear Data.
- [x] **Categories:** Manage categories (Add, Delete).

## Phase 6: macOS / Xcode Setup (Deferred)
*These steps will be executed when cloning the repo on a Mac.*
- [ ] Create a new macOS App project in Xcode (`YNAB`).
- [ ] Drag and drop the `YNAB/App`, `Models`, `Services`, `ViewModels`, `Views`, and `Components` folders into the Xcode project.
- [ ] Set minimum deployment target to `macOS 13.0` and Swift to `5.9`.
- [ ] Add `firebase-ios-sdk` via Swift Package Manager (`FirebaseAuth`, `FirebaseFirestore`).
- [ ] Add `GoogleService-Info.plist` to the project root.
- [ ] Enable `Outgoing Connections (Client)` in App Sandbox Entitlements.
- [ ] Build and Run!

## Current Status
- Architecture defined: ✅ Yes
- UI Designs/Components specified: ✅ Yes
- State Management planned: ✅ Yes
- Backend configured (Firebase): ⏳ Pending Setup
- Native Views built: ⏳ Pending Implementation
