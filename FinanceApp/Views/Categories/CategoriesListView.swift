import SwiftUI

struct CategoriesListView: View {
    @StateObject private var viewModel: CategoriesViewModel
    @State private var showAddCategory = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.categories.isEmpty {
                    ProgressView()
                } else if viewModel.categories.isEmpty {
                    EmptyStateView(
                        icon: "tag",
                        title: "No Categories",
                        message: "Create categories to organize your transactions."
                    )
                } else {
                    categoriesList
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadCategories()
            }
            .refreshable {
                viewModel.loadCategories()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    private var categoriesList: some View {
        List {
            ForEach(viewModel.categories) { category in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Text(category.icon)
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.body.weight(.medium))
                        if let created = category.createdAt {
                            Text("Added \(DateUtils.relativeString(created))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteCategory(categoryId: viewModel.categories[index].id)
                }
            }
        }
    }
}
