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
                
            BudgetListView()
                .tabItem { Label("Budgets", systemImage: "chart.pie") }
                .tag(2)
                
            RecurringListView()
                .tabItem { Label("Recurring", systemImage: "arrow.triangle.2.circlepath") }
                .tag(3)

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar") }
                .tag(4)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(5)
        }
    }
}
