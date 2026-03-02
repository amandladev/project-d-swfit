import SwiftUI

struct AddTagView: View {
    @ObservedObject var viewModel: TagsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = TagColorOption.defaultOption

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
            }
            .navigationTitle(L10n.tr("tags.newTag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.create")) {
                        viewModel.createTag(
                            name: name.trimmingCharacters(in: .whitespaces),
                            color: selectedColor.hex
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

// MARK: - Tag Color Options

struct TagColorOption: Identifiable {
    let id: String
    let hex: String
    let color: Color

    static let defaultOption = TagColorOption(id: "emerald", hex: "#2ECC71", color: Color(hex: "#2ECC71"))

    static let allOptions: [TagColorOption] = [
        TagColorOption(id: "emerald",  hex: "#2ECC71", color: Color(hex: "#2ECC71")),
        TagColorOption(id: "blue",     hex: "#3498DB", color: Color(hex: "#3498DB")),
        TagColorOption(id: "purple",   hex: "#9B59B6", color: Color(hex: "#9B59B6")),
        TagColorOption(id: "orange",   hex: "#E67E22", color: Color(hex: "#E67E22")),
        TagColorOption(id: "red",      hex: "#E74C3C", color: Color(hex: "#E74C3C")),
        TagColorOption(id: "teal",     hex: "#1ABC9C", color: Color(hex: "#1ABC9C")),
        TagColorOption(id: "pink",     hex: "#E91E8F", color: Color(hex: "#E91E8F")),
        TagColorOption(id: "yellow",   hex: "#F1C40F", color: Color(hex: "#F1C40F")),
        TagColorOption(id: "indigo",   hex: "#5C6BC0", color: Color(hex: "#5C6BC0")),
        TagColorOption(id: "cyan",     hex: "#00BCD4", color: Color(hex: "#00BCD4")),
        TagColorOption(id: "brown",    hex: "#795548", color: Color(hex: "#795548")),
        TagColorOption(id: "slate",    hex: "#607D8B", color: Color(hex: "#607D8B")),
    ]
}
