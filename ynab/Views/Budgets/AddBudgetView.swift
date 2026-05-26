import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: TransactionViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var selectedCategoryId: String = ""
    @State private var limitAmountString: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategoryId) {
                        Text("None").tag("")
                        ForEach(vm.categories.filter { $0.type == .expense }) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.name)
                            }.tag(cat.id)
                        }
                    }
                }
                
                Section(header: Text("Monthly Limit")) {
                    TextField("Amount", text: $limitAmountString)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }
            .navigationTitle("Add Budget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(selectedCategoryId.isEmpty || Double(limitAmountString) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let amount = Double(limitAmountString), !selectedCategoryId.isEmpty else { return }
        guard let userId = authVM.currentUser?.uid else { return }
        
        Task {
            await vm.addBudget(userId: userId, categoryId: selectedCategoryId, limitAmount: amount)
            dismiss()
        }
    }
}
