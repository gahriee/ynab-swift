import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM:        AuthViewModel
    @EnvironmentObject var transactionVM: TransactionViewModel
    @State private var currencyInput  = ""
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Currency
                Section {
                    HStack {
                        Label("Currency Symbol", systemImage: "dollarsign.circle.fill")
                            .foregroundColor(AppColors.primary)
                        Spacer()
                        TextField("e.g. PHP, $, €", text: $currencyInput)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .onAppear { currencyInput = transactionVM.settings.currencySymbol }
                            .onSubmit { saveSettings() }
                    }
                } header: {
                    Text("Currency").foregroundColor(.white)
                }

                // Appearance
                Section {
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
                            .foregroundColor(AppColors.primary)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { transactionVM.settings.themeMode },
                            set: { newMode in
                                Task {
                                    await transactionVM.updateSettings(
                                        userId: authVM.currentUser?.uid ?? "",
                                        updated: transactionVM.settings.copyWith(themeMode: newMode)
                                    )
                                }
                            }
                        )) {
                            ForEach(AppThemeMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue.capitalized).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }
                } header: {
                    Text("Appearance").foregroundColor(.white)
                }

                // Account
                Section {
                    if let email = authVM.currentUser?.email {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Signed in as", systemImage: "person.crop.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text(email)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .padding(.leading, 32)
                        }
                        .padding(.vertical, 4)
                    }
                    Button(role: .destructive) { authVM.logout() } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Account").foregroundColor(.white)
                }

                // Data
                Section {
                    NavigationLink {
                        CategoryListView()
                    } label: {
                        Label("Manage Categories", systemImage: "square.grid.2x2.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Data").foregroundColor(.white)
                }
            }
            .formStyle(.grouped)
            .foregroundColor(.white)
            .navigationTitle("Settings")
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    Task {
                        await transactionVM.clearAllData(userId: authVM.currentUser?.uid ?? "")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all transactions and reset categories. This cannot be undone.")
            }
        }
    }

    private func saveSettings() {
        Task {
            await transactionVM.updateSettings(
                userId: authVM.currentUser?.uid ?? "",
                updated: transactionVM.settings.copyWith(currencySymbol: currencyInput)
            )
        }
    }
}
