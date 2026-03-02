import SwiftUI

struct TagsListView: View {
    @StateObject private var viewModel: TagsViewModel
    @State private var showAddTag = false
    @State private var editingTag: Tag?

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: TagsViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tags.isEmpty {
                    BrandedLoadingView()
                } else if viewModel.tags.isEmpty {
                    EmptyStateView(
                        icon: "number",
                        title: L10n.tr("tags.noTags"),
                        message: L10n.tr("tags.noTagsMessage")
                    )
                } else {
                    tagsList
                }
            }
            .navigationTitle(L10n.tr("tags.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTag) {
                AddTagView(viewModel: viewModel)
            }
            .sheet(item: $editingTag) { tag in
                EditTagView(viewModel: viewModel, tag: tag)
            }
            .onAppear {
                viewModel.loadTags()
            }
            .refreshable {
                viewModel.loadTags()
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

    private var tagsList: some View {
        List {
            ForEach(viewModel.tags) { tag in
                Button {
                    editingTag = tag
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(tag.swiftUIColor)
                            .frame(width: 14, height: 14)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(tag.name)
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(.primary)
                            if let created = tag.createdAt {
                                Text(L10n.tr("tags.added %@", DateUtils.relativeString(created)))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteTag(tagId: tag.id)
                    } label: {
                        Label(L10n.tr("common.delete"), systemImage: "trash")
                    }
                }
            }
        }
    }
}
