import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @EnvironmentObject var authVM:        AuthViewModel
    @State private var showAddSheet = false
    @State private var editingTx:   Transaction?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primary.opacity(0.02)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Balance card
                        BalanceCard(
                            balance:        transactionVM.balance,
                            income:         transactionVM.totalIncome,
                            expense:        transactionVM.totalExpense,
                            currencySymbol: transactionVM.settings.currencySymbol
                        )
                        .padding(.top, 16)

                        recentTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Dashboard")
            .overlay(alignment: .bottomTrailing) {
                Button { showAddSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("Transaction")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(24)
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView(userId: authVM.currentUser?.uid ?? "")
                    #if os(iOS)
                    .presentationDetents([.fraction(0.85), .large])
                    #endif
            }
            .sheet(item: $editingTx) { tx in
                AddTransactionView(userId: authVM.currentUser?.uid ?? "", editing: tx)
                    #if os(iOS)
                    .presentationDetents([.fraction(0.85), .large])
                    #endif
            }
        }
    }

    @ViewBuilder
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if transactionVM.recentTransactions.isEmpty {
                EmptyStateView(message: "No transactions yet")
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(transactionVM.recentTransactions) { tx in
                        TransactionRow(
                            transaction:    tx,
                            category:       transactionVM.categories.first { $0.id == tx.categoryId },
                            currencySymbol: transactionVM.settings.currencySymbol
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { editingTx = tx }
                    }
                }
            }
        }
    }
}
