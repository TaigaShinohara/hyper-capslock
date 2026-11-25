import HyperCapsLockCore
import SwiftUI

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

extension HyperTriggerMode {
    var keyInstructionName: String {
        self == .capsLockAndEisuu ? "CapsLock または英数" : title
    }
}

struct KeyComboView: View {
    let trigger: HyperTriggerMode
    let key: String

    var body: some View {
        HStack(spacing: 4) {
            KeyCapView(label: trigger.keyInstructionName)
            Text("+")
                .font(.caption2)
                .foregroundStyle(.secondary)
            KeyCapView(label: key)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trigger.keyInstructionName) を押したまま \(key)")
    }
}
