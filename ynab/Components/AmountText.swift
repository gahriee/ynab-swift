import SwiftUI

/// Always use this view for any monetary amount — never hardcode colors in screens.
struct AmountText: View {
    let amount:         Double
    let type:           TransactionType
    let currencySymbol: String
    var font: Font = .system(.body, design: .rounded)

    var body: some View {
        Text("\(type.sign)\(currencySymbol)\(String(format: "%.2f", amount))")
            .font(font)
            .fontWeight(.bold)
            .foregroundColor(type.color)
            .monospacedDigit()
    }
}
