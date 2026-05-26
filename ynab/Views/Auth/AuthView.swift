import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email    = ""
    @State private var password = ""
    @State private var isLogin  = true

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                headerSection
                
                VStack(spacing: 20) {
                    formSection
                    
                    if let error = authVM.error {
                        Text(error)
                            .foregroundColor(AppColors.warning)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    actionSection
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 48)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: 15)
            )
            .frame(maxWidth: 420)
            .animation(.easeInOut(duration: 0.3), value: isLogin)
            .animation(.easeInOut, value: authVM.error)
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: isLogin ? "lock.fill" : "person.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(spacing: 8) {
                Text(isLogin ? "Welcome Back" : "Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(isLogin ? "Sign in to manage your finances" : "Start tracking your finances today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email").font(.caption).foregroundColor(.secondary)
                TextField("name@example.com", text: $email)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Password").font(.caption).foregroundColor(.secondary)
                SecureField("••••••••", text: $password)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
    
    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: handleAuth) {
                ZStack {
                    if authVM.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(isLogin ? "Sign In" : "Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(authVM.isLoading ? AppColors.primary.opacity(0.7) : AppColors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
            
            Button(action: {
                withAnimation {
                    isLogin.toggle()
                    authVM.error = nil
                }
            }) {
                Text(isLogin ? "Don't have an account? Register" : "Already have an account? Sign in")
                    .font(.footnote)
                    .foregroundColor(AppColors.primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func handleAuth() {
        Task {
            if isLogin {
                await authVM.login(email: email, password: password)
            } else {
                await authVM.register(email: email, password: password)
            }
        }
    }
}
