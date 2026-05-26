import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel

    @State private var showForm = false
    @State private var editingCategory: Category?
    @State private var newName   = ""
    @State private var newIcon   = "tag.fill"
    @State private var newType:    TransactionType = .expense
    @State private var errorMsg: String?

    var body: some View {
        List {
            ForEach(transactionVM.categories) { cat in
                HStack(spacing: 16) {
                    CategoryIcon(icon: cat.icon)
                    
                    Text(cat.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(cat.type.label.uppercased())
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(cat.type.color.opacity(0.15))
                        .foregroundColor(cat.type.color)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    editingCategory = cat
                    newName = cat.name
                    newIcon = cat.icon
                    newType = cat.type
                    showForm = true
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            let ok = await transactionVM.deleteCategory(id: cat.id)
                            if !ok { errorMsg = "Reassign or delete transactions first" }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingCategory = nil
                    newName = ""
                    newIcon = "tag.fill"
                    newType = .expense
                    showForm = true
                } label: { 
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showForm) {
            categoryFormSheet
                #if os(iOS)
                .presentationDetents([.fraction(0.8), .large])
                #endif
        }
        .alert("Cannot delete", isPresented: .constant(errorMsg != nil), actions: {
            Button("OK") { errorMsg = nil }
        }, message: { Text(errorMsg ?? "") })
    }
    
    @ViewBuilder
    private var categoryFormSheet: some View {
        VStack(spacing: 24) {
            Text(editingCategory == nil ? "New Category" : "Edit Category")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.caption).foregroundColor(.secondary)
                    TextField("Groceries, Salary, etc.", text: $newName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon").font(.caption).foregroundColor(.secondary)
                    
                    let predefinedIcons = [
                        "cart.fill", "fork.knife", "car.fill", "house.fill", "bolt.fill", "wifi",
                        "cross.case.fill", "heart.fill", "graduationcap.fill", "airplane", "bus.fill", "gamecontroller.fill",
                        "display", "tshirt.fill", "gift.fill", "tag.fill", "briefcase.fill", "banknote.fill"
                    ]
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(predefinedIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(newIcon == icon ? .white : AppColors.primary)
                                .frame(width: 40, height: 40)
                                .background(newIcon == icon ? AppColors.primary : Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                                .onTapGesture { newIcon = icon }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type").font(.caption).foregroundColor(.secondary)
                    Picker("Type", selection: $newType) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            HStack(spacing: 16) {
                Button(action: { showForm = false }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        if let cat = editingCategory {
                            await transactionVM.updateCategory(Category(id: cat.id, userId: cat.userId, name: newName, icon: newIcon, type: newType))
                        } else {
                            await transactionVM.addCategory(
                                userId: authVM.currentUser?.uid ?? "",
                                name: newName, icon: newIcon, type: newType
                            )
                        }
                        showForm = false
                    }
                }) {
                    Text(editingCategory == nil ? "Add" : "Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(newName.isEmpty ? AppColors.primary.opacity(0.5) : AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(newName.isEmpty)
            }
        }
        .padding(32)
        .frame(maxWidth: 360)
        .background(.regularMaterial)
    }
}
