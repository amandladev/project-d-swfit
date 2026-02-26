import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var viewModel: CategoriesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "💰"

    private let icons = [
        "💰", "🏠", "🍔", "🚗", "✈️", "🎮", "📱", "💊",
        "📚", "🎬", "🛒", "💳", "🏋️", "🐾", "🎁", "⚡",
        "💼", "🎵", "👕", "🔧", "📦", "🏦", "💸", "🎯",
        "☕", "🍕", "🚌", "🏥", "🎓", "🏖️", "🧾", "💡"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    HStack(spacing: 12) {
                        Text(selectedIcon)
                            .font(.largeTitle)
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                        TextField("Category Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                Section("Choose an Icon") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 8),
                        spacing: 10
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            Text(icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon
                                              ? Color.accentColor.opacity(0.2)
                                              : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedIcon == icon
                                                ? Color.accentColor
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedIcon = icon
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon
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
