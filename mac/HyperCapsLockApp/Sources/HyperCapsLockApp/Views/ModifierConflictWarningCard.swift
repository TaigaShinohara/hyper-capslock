import HyperCapsLockCore
import SwiftUI

/// システム設定の「修飾キー」で CapsLock が別キーに変更されている場合の案内カード。
struct ModifierConflictWarningCard: View {
    let conflicts: [CapsLockSystemConflict]
    let onOpenKeyboardSettings: () -> Void
    let onRecheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("CapsLock が別キーに割り当てられています")
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(conflicts) { conflict in
                    Text("\(conflict.deviceName)：\(conflict.mappedDestinationName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("キーボード設定 → ショートカット → 修飾キー で CapsLock を標準に戻してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("キーボード設定を開く") {
                    onOpenKeyboardSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("再確認") {
                    onRecheck()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
