import SwiftUI

@main
struct FinanceAppMain: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appViewModel.isLoading {
                    LaunchView()
                } else if appViewModel.needsOnboarding {
                    SetupView(appViewModel: appViewModel)
                } else if let user = appViewModel.currentUser {
                    ContentView(userId: user.id)
                } else if let error = appViewModel.error {
                    ErrorView(message: error) {
                        appViewModel.initialize()
                    }
                }
            }
            .onAppear {
                appViewModel.initialize()
            }
        }
    }
}

// MARK: - Launch Screen

private struct LaunchView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulse ? 1.12 : 0.92)
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.accent)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            Text("Finance App")
                .font(AppTheme.displayFont(24))

            ProgressView()
                .tint(AppTheme.accent)
                .padding(.top, 4)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.expense.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.expense)
            }

            Text("Something went wrong")
                .font(AppTheme.displayFont(22))

            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding()
    }
}
