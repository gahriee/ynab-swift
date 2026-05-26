import SwiftUI

struct TransactionRow: View {
    let transaction:    Transaction
    let category:       Category?
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 16) {
            CategoryIcon(
                icon: category?.icon ?? "questionmark",
                size: 48,
                color: category?.type.color ?? AppColors.primary
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "Uncategorized")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                AmountText(
                    amount: transaction.amount,
                    type: transaction.type,
                    currencySymbol: currencySymbol,
                    font: .system(.headline, design: .rounded)
                )
                
                if transaction.note != nil && !transaction.note!.isEmpty {
                    Text(transaction.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
