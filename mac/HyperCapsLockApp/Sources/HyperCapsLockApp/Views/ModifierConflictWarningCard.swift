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
                    .foregroundStyle(AppTheme.orange)
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
                Text("現在の割り当てはそのまま使えます。別のキーボードか JIS 英数を選ぶか、有効化を見送れます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("macOS の設定を確認") {
                    onOpenKeyboardSettings()
                }
                .buttonStyle(.bordered)
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
        .background(AppTheme.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
