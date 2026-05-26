import SwiftUI

struct RecurringListView: View {
    @EnvironmentObject var vm: TransactionViewModel
    @State private var showAddRecurring = false

    var body: some View {
        NavigationStack {
            List {
                if vm.recurringTransactions.isEmpty {
                    Text("No recurring transactions. Add one to automate your tracking!")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(vm.recurringTransactions) { recurring in
                        let cat = vm.categories.first(where: { $0.id == recurring.categoryId })
                        let name = cat?.name ?? "Unknown Category"
                        let icon = cat?.icon ?? "questionmark"
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(recurring.type.color)
                                Text(name)
                                    .font(.headline)
                                Spacer()
                                Text("\(recurring.type.sign)\(vm.settings.currencySymbol) \(recurring.amount, specifier: "%.2f")")
                                    .foregroundColor(recurring.type.color)
                                    .fontWeight(.bold)
                            }
                            HStack {
                                Text("\(recurring.frequency.label) · Starting \(recurring.startDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let note = recurring.note, !note.isEmpty {
                                    Spacer()
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await vm.deleteRecurringTransaction(id: recurring.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddRecurring = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRecurring) {
                AddRecurringView()
            }
        }
    }
}
