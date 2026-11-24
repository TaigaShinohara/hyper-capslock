import SwiftUI

/// キー操作を文字の説明ではなく物理キーの形で伝える共通パーツ。
struct KeyCapView: View {
    let label: String
    var highlighted: Bool = false

    var body: some View {
        Text(label)
            .font(.system(.caption, design: .monospaced).weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                highlighted ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        highlighted ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.16),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(highlighted ? Color.accentColor : .primary)
    }
}

/// CapsLock + 別キーの組み合わせを視覚的に示すバッジ。
struct KeyComboView: View {
    let key: String
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            KeyCapView(label: "Caps", highlighted: highlighted)
            Text("+")
                .font(.caption2)
                .foregroundStyle(.secondary)
            KeyCapView(label: key, highlighted: highlighted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CapsLock と \(key)")
    }
}
