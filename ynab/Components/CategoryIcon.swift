import SwiftUI

struct CategoryIcon: View {
    let icon: String
    var size: CGFloat = 40
    var color: Color = AppColors.primary

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
