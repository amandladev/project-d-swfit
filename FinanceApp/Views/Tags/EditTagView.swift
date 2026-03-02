import SwiftUI

struct EditTagView: View {
    @ObservedObject var viewModel: TagsViewModel
    let tag: Tag
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedColor: TagColorOption

    init(viewModel: TagsViewModel, tag: Tag) {
        self.viewModel = viewModel
        self.tag = tag
        _name = State(initialValue: tag.name)

        // Match existing color or fall back to default
        let matching = TagColorOption.allOptions.first {
            $0.hex.lowercased() == (tag.color ?? "").lowercased()
        }
        _selectedColor = State(initialValue: matching ?? TagColorOption.defaultOption)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.tr("tags.tagDetails")) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(selectedColor.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                            )

                        TextField(L10n.tr("tags.tagName"), text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                Section(L10n.tr("tags.color")) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 12
                    ) {
                        ForEach(TagColorOption.allOptions) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor.id == option.id
                                                ? Color.primary
                                                : Color.clear,
                                            lineWidth: 2.5
                                        )
                                )
                                .overlay(
                                    selectedColor.id == option.id
                                        ? Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                        : nil
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedColor = option
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.deleteTag(tagId: tag.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(L10n.tr("tags.deleteTag"))
                        }
                    }
                }
            }
            .navigationTitle(L10n.tr("tags.editTag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.save")) {
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        viewModel.updateTag(
                            tagId: tag.id,
                            name: trimmedName != tag.name ? trimmedName : nil,
                            color: selectedColor.hex != (tag.color ?? "") ? selectedColor.hex : nil
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
