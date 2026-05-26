# YNAB Swift — Agent Guidelines

**Hello, fellow Agent!** If you are reading this, you are working on the YNAB Swift application. This document outlines the strict architectural rules and patterns you must follow.

## Core Stack
- **Platform:** macOS 13 (Ventura)+
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Backend:** Firebase (Auth & Firestore) via Swift Package Manager.

## The Golden Rule
> **"If SwiftUI can do it, we don't add a package for it."**
Do not import or suggest third-party packages for state management, navigation, UI components, or charts. We rely solely on native Apple frameworks and the official Firebase SDK.

## Data Models
- Located in `YNAB/Models/`.
- Use plain Swift structs.
- Do NOT use SwiftData or CoreData.
- Do NOT use Code Generation or property wrappers for Firebase parsing. Implement manual `fromDict` and `toDict` static methods for Firestore compatibility.

## Services (Backend Interaction)
- Located in `YNAB/Services/`.
- Services are plain classes (marked `final`) that wrap Firebase logic.
- They must NOT hold application state or business logic. They solely exist to read/write/listen to Firebase.
- Always use the asynchronous `async/await` syntax for single requests and Swift's continuation/closures for Snapshot listeners.

## State Management (ViewModels)
- Located in `YNAB/ViewModels/`.
- Use Apple's native `ObservableObject` with `@Published` properties.
- Classes must be marked with `@MainActor` to ensure UI updates happen on the main thread.
- Avoid passing data manually down the view tree; utilize `.environmentObject()` at the root and `@EnvironmentObject` within child views.

## User Interface (Views & Components)
- Located in `YNAB/Views/` and `YNAB/Components/`.
- **Navigation:** Use `TabView` for main navigation and `NavigationStack` / `NavigationLink` for hierarchical flows.
- **Icons:** Exclusively use Apple's SF Symbols via `Image(systemName: "symbol.name")`. Do not import image assets for icons.
- **Charts:** Use the native macOS 13 `Charts` framework.
- **Styling:** Adhere to the colors defined in `AppTheme.swift`. Do not hardcode hex colors directly into the views.

## File Structure & File Modification
- Always check the `project-status.md` to see current progress.
- Make edits exclusively within the `YNAB/` directory.

## Core Modules
- **Budget Module:** Handles monthly spending limits per category, utilizing progress bars and comparative charts.
- **Recurring Module:** Manages automated or scheduled transactions (e.g., subscriptions, regular income). Ensure to implement logic for generating due transactions on app launch or via Firebase functions.

*Follow these rules closely to maintain a clean, native, and maintainable SwiftUI codebase.*

## Troubleshooting & Gotchas
- **Complex View Expressions:** If the compiler throws *"The compiler is unable to type-check this expression in reasonable time"*, it means the SwiftUI `body` block is too large. Break down large `VStack` or `HStack` chunks into smaller, private `@ViewBuilder` variables or separate structs.
- **`.onChange` Deprecation:** In iOS 17 / macOS 14+, `.onChange(of: value) { _ in }` is deprecated. Use the zero-parameter closure instead: `.onChange(of: value) { }`.
- **Cross-Platform Colors:** Avoid using `NSColor` directly (e.g., `Color(nsColor: .windowBackgroundColor)`) unless explicitly importing `AppKit`. Instead, prefer generic Semantic colors like `Color.secondary.opacity(0.1)` to ensure the codebase remains compiler-friendly across Apple platforms.
