import SwiftUI

struct BudgetListView: View {
    @EnvironmentObject var vm: TransactionViewModel
    @State private var showAddBudget = false

    var body: some View {
        NavigationStack {
            List {
                if vm.budgets.isEmpty {
                    Text("No budgets set yet. Add one to get started!")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(vm.budgets) { budget in
                        let cat = vm.categories.first(where: { $0.id == budget.categoryId })
                        let name = cat?.name ?? "Unknown Category"
                        let icon = cat?.icon ?? "questionmark"
                        
                        let progress = vm.budgetProgress(for: budget.categoryId, month: Date())
                        let spent = progress?.spent ?? 0
                        let limit = budget.limitAmount
                        let percentage = limit > 0 ? (spent / limit) : 0
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(cat?.type.color ?? .primary)
                                Text(name)
                                    .font(.headline)
                                Spacer()
                                Text("\(vm.settings.currencySymbol) \(spent, specifier: "%.2f") / \(limit, specifier: "%.2f")")
                                    .font(.subheadline)
                            }
                            ProgressView(value: min(percentage, 1.0))
                                .progressViewStyle(.linear)
                                .tint(percentage > 1.0 ? .red : AppColors.primary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await vm.deleteBudget(id: budget.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddBudget = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }
        }
    }
}
