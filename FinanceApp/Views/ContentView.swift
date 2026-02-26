import SwiftUI

struct ContentView: View {
    let userId: String

    var body: some View {
        TabView {
            DashboardView(userId: userId)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }

            AccountsListView(userId: userId)
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }

            CategoriesListView(userId: userId)
                .tabItem {
                    Label("Categories", systemImage: "tag")
                }
        }
    }
}
