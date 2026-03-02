import SwiftUI

/// Branded loading indicator with animated pulsing rings.
struct BrandedLoadingView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(AppTheme.accent.opacity(0.2), lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.3 : 0.9)
                    .opacity(isAnimating ? 0 : 0.6)

                // Middle pulse ring
                Circle()
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isAnimating ? 1.2 : 0.95)
                    .opacity(isAnimating ? 0.1 : 0.8)

                // Core icon
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
                    .scaleEffect(pulseScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.0
                }
            }

            Text(L10n.tr("common.loading"))
                .font(AppTheme.captionFont)
                .foregroundColor(.secondary)
        }
    }
}

/// Inline spinner matching app branding — use in pull-to-refresh or inline slots.
struct InlineLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.title3)
            .foregroundStyle(AppTheme.accent)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
