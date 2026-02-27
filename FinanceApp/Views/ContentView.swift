import SwiftUI

struct ContentView: View {
    let userId: String
    @State private var showQuickAdd = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                DashboardView(userId: userId)
                    .tag(0)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie.fill")
                    }

                AccountsListView(userId: userId)
                    .tag(1)
                    .tabItem {
                        Label("Accounts", systemImage: "creditcard.fill")
                    }

                CategoriesListView(userId: userId)
                    .tag(2)
                    .tabItem {
                        Label("Categories", systemImage: "tag.fill")
                    }
            }
            .tint(AppTheme.accent)

            // Floating Action Button — hidden on Accounts tab
            if selectedTab != 1 {
                Button {
                    showQuickAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                                .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, y: 5)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 70)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddTransactionView(userId: userId)
                .presentationDetents([.large])
        }
    }
}
