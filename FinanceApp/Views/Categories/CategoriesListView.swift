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
                    BrandedLoadingView()
                } else if viewModel.categories.isEmpty {
                    EmptyStateView(
                        icon: "tag",
                        title: L10n.tr("categories.noCategories"),
                        message: L10n.tr("categories.noCategoriesMessage")
                    )
                } else {
                    categoriesList
                }
            }
            .navigationTitle(L10n.tr("categories.title"))
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
            .alert(L10n.tr("common.error"), isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button(L10n.tr("common.ok")) { viewModel.error = nil }
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
                            .fill(AppTheme.accent.opacity(0.10))
                            .frame(width: 42, height: 42)
                        Text(category.icon)
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.name)
                            .font(.system(.body, design: .rounded).weight(.medium))
                        if let created = category.createdAt {
                            Text(L10n.tr("categories.added %@", DateUtils.relativeString(created)))
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteCategory(categoryId: category.id)
                    } label: {
                        Label(L10n.tr("common.delete"), systemImage: "trash")
                    }
                }
            }
        }
    }
}
