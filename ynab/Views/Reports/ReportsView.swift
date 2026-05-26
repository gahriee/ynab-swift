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
            ZStack {
                Color.secondary.opacity(0.03)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        monthNavigator
                        totalsSection
                        breakdownSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Reports")
        }
    }
    
    @ViewBuilder
    private var monthNavigator: some View {
        HStack {
            Button { stepMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            
            Spacer()
            
            Button { stepMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var totalsSection: some View {
        HStack(spacing: 16) {
            // Income Box
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(AppColors.income.opacity(0.15))
                        .frame(width: 24, height: 24)
                        .overlay(Image(systemName: "arrow.down").font(.caption).foregroundColor(AppColors.income))
                    
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                AmountText(
                    amount: totals.income, type: .income,
                    currencySymbol: transactionVM.settings.currencySymbol,
                    font: .system(.title3, design: .rounded)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            
            // Expense Box
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(AppColors.expense.opacity(0.15))
                        .frame(width: 24, height: 24)
                        .overlay(Image(systemName: "arrow.up").font(.caption).foregroundColor(AppColors.expense))
                    
                    Text("Expense")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                AmountText(
                    amount: totals.expense, type: .expense,
                    currencySymbol: transactionVM.settings.currencySymbol,
                    font: .system(.title3, design: .rounded)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if breakdown.isEmpty {
                    EmptyStateView(message: "No expenses this month", icon: "chart.pie.fill")
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(breakdown.enumerated()), id: \.element.0.id) { index, element in
                        let (cat, amount) = element
                        
                        HStack(spacing: 16) {
                            CategoryIcon(icon: cat.icon)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(cat.name)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(transactionVM.settings.currencySymbol)\(String(format: "%.2f", amount))")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(AppColors.expense)
                                        .monospacedDigit()
                                }
                                
                                ProgressView(
                                    value: amount,
                                    total: max(totals.expense, 1)
                                )
                                .tint(AppColors.expense)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if index < breakdown.count - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }

    private func stepMonth(_ delta: Int) {
        withAnimation {
            selectedMonth = Calendar.current.date(
                byAdding: .month, value: delta, to: selectedMonth
            ) ?? selectedMonth
        }
    }
}
