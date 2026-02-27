import SwiftUI

/// Reusable empty state placeholder with icon, title, and message.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.accent.opacity(0.6))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }

            Text(title)
                .font(AppTheme.displayFont(22))

            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
