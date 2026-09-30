import SwiftUI

struct ClipRow: View {
    let item: ClipItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(item.isPinned ? Theme.accent : .secondary)
                .frame(width: 18, height: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.isMultiline ? item.singleLine : item.content)
                    .font(Theme.font(for: item.kind))
                    .foregroundStyle(.primary)
                    .lineLimit(item.kind == .code ? 3 : 2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                HStack(spacing: 6) {
                    Text(item.kind.label)
                    Text(item.createdAt, style: .relative)
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}
