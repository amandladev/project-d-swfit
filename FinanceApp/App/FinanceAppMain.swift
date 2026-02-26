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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            ProgressView()
                .padding(.top, 8)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Something went wrong")
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
