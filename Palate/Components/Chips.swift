import SwiftUI

/// A contextual "What are you feeling?" chip (occasion).
struct ContextChip: View {
    let occasion: Occasion
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Label(occasion.label, systemImage: occasion.symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 9)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.card),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(Theme.separator.opacity(isSelected ? 0 : 0.6), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

/// A cuisine / taste tag chip.
struct CuisineChip: View {
    let text: String
    var symbol: String? = nil
    var isSelected: Bool = false
    var tint: Color = Theme.accent
    var action: (() -> Void)? = nil

    var body: some View {
        let content = HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.caption2) }
            Text(text).font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.card), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.separator.opacity(isSelected ? 0 : 0.6), lineWidth: 0.5))

        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

/// A simple flow layout that wraps chips onto multiple lines (iOS 16+ Layout API).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
                rows.append(0)
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// A reusable section header with an optional trailing action.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).sectionTitleStyle()
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline.weight(.semibold))
            }
        }
    }
}
