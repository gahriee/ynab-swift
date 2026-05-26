import SwiftUI

struct AddRecurringView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: TransactionViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var amountString: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryId: String = ""
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var note: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type & Amount")) {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Amount", text: $amountString)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategoryId) {
                        Text("None").tag("")
                        ForEach(vm.categories.filter { $0.type == type }) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.name)
                            }.tag(cat.id)
                        }
                    }
                    // Reset category if type changes and current category doesn't match
                    .onChange(of: type) { _ in
                        selectedCategoryId = ""
                    }
                }
                
                Section(header: Text("Recurrence")) {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { f in
                            Text(f.label).tag(f)
                        }
                    }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section(header: Text("Optional Note")) {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Add Recurring")
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
                    .disabled(selectedCategoryId.isEmpty || Double(amountString) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let amount = Double(amountString), !selectedCategoryId.isEmpty else { return }
        guard let userId = authVM.currentUser?.uid else { return }
        
        let finalNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await vm.addRecurringTransaction(
                userId: userId,
                amount: amount,
                type: type,
                categoryId: selectedCategoryId,
                frequency: frequency,
                startDate: startDate,
                note: finalNote.isEmpty ? nil : finalNote
            )
            dismiss()
        }
    }
}
