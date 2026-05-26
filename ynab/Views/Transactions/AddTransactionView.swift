import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var transactionVM: TransactionViewModel
    @Environment(\.dismiss) private var dismiss

    let userId:  String
    var editing: Transaction? = nil   // nil = add mode, non-nil = edit mode

    @State private var amountText  = ""
    @State private var type:         TransactionType = .expense
    @State private var categoryId  = ""
    @State private var date        = Date()
    @State private var note        = ""

    private var filteredCategories: [Category] {
        transactionVM.categories.filter { $0.type == type }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.system(.body, design: .rounded))
                
                Spacer()
                
                Text(editing == nil ? "Add Transaction" : "Edit Transaction")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Save") {
                    Task { await save(); dismiss() }
                }
                .buttonStyle(.plain)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundColor((amountText.isEmpty || categoryId.isEmpty) ? .secondary : AppColors.primary)
                .disabled(amountText.isEmpty || categoryId.isEmpty)
            }
            .padding()
            .background(.regularMaterial)

            Divider()

            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text(transactionVM.settings.currencySymbol)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $amountText)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { categoryId = "" }
                }

                Section {
                    Picker("Category", selection: $categoryId) {
                        Text("Select…").tag("")
                        ForEach(filteredCategories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    TextField("Add a note (optional)…", text: $note)
                }
            }
            .formStyle(.grouped)
        }
        .frame(maxWidth: 420, maxHeight: 500)
        .onAppear {
            if let tx = editing {
                amountText = String(format: "%.2f", tx.amount)
                type       = tx.type
                categoryId = tx.categoryId
                date       = tx.date
                note       = tx.note ?? ""
            }
        }
    }

    private func save() async {
        guard let amount = Double(amountText) else { return }
        if let tx = editing {
            await transactionVM.updateTransaction(
                Transaction(id: tx.id, userId: userId, amount: amount,
                            type: type, categoryId: categoryId, date: date,
                            note: note.isEmpty ? nil : note)
            )
        } else {
            await transactionVM.addTransaction(
                userId: userId, amount: amount, type: type,
                categoryId: categoryId, date: date, note: note.isEmpty ? nil : note
            )
        }
    }
}
