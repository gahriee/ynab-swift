import SwiftUI

struct BalanceCard: View {
    let balance:        Double
    let income:         Double
    let expense:        Double
    let currencySymbol: String

    var body: some View {
        VStack(spacing: 20) {
            // Top Section: Total Balance
            VStack(spacing: 4) {
                Text("Total Balance")
                    .font(.caption)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(currencySymbol)\(String(format: "%.2f", balance))")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(.top, 10)
            
            // Bottom Section: Income & Expense
            HStack(spacing: 16) {
                // Income
                BalanceStatView(title: "Income", amount: income, icon: "arrow.down.circle.fill", color: .green, currencySymbol: currencySymbol)
                
                // Expense
                BalanceStatView(title: "Expense", amount: expense, icon: "arrow.up.circle.fill", color: .red, currencySymbol: currencySymbol)
            }
        }
        .padding(24)
        .background(
            ZStack {
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle decorative shapes
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150)
                    .offset(x: 100, y: -50)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100)
                    .offset(x: -120, y: 80)
            }
            .clipped()
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: AppColors.primary.opacity(0.25), radius: 20, x: 0, y: 12)
    }
}

private struct BalanceStatView: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let currencySymbol: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.9))
                .background(Circle().fill(.white).frame(width: 20, height: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                Text("\(currencySymbol)\(String(format: "%.2f", amount))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
