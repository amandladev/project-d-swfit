import SwiftUI

/// Inline tag picker section for Add / Edit transaction forms.
/// Shows a horizontal scrollable list where tapping toggles each tag.
struct TransactionTagPicker: View {
    @ObservedObject var tagsVM: TagsViewModel
    let transactionId: String?
    @Binding var selectedTagIds: Set<String>

    var body: some View {
        Section(L10n.tr("tags.title")) {
            if tagsVM.tags.isEmpty {
                Text(L10n.tr("tags.noTagsAvailable"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tagsVM.tags) { tag in
                        let isSelected = selectedTagIds.contains(tag.id)
                        TagChip(tag: tag, isSelected: isSelected) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if isSelected {
                                    selectedTagIds.remove(tag.id)
                                } else {
                                    selectedTagIds.insert(tag.id)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Circle()
                    .fill(tag.swiftUIColor)
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? tag.swiftUIColor.opacity(0.18) : Color(.tertiarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? tag.swiftUIColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? tag.swiftUIColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}
