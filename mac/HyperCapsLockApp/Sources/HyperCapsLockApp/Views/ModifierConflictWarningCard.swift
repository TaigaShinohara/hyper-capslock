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
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text("システム設定の「修飾キー」と競合しています")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(conflicts) { conflict in
                    Text("「\(conflict.deviceName)」で CapsLock が「\(conflict.mappedDestinationName)」に変更されているため、そのままでは CapsLock キーに反応しません。")
                        .font(.callout)
                }
                Text("※ Command ↔ Control など他のキーの入れ替え設定は、そのまま残して大丈夫です。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("直し方：")
                    .font(.caption.bold())
                Text("1. 下のボタンで「キーボード設定」を開き、「キーボードショートカット…」→「修飾キー」を選ぶ")
                Text("2. 「Caps Lock キー」だけを「Caps Lock」に戻して「完了」を押す")
                Text("（システム設定を変えたくない場合は、スペース左の「英数」キーを ON にして使えます）")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("キーボード設定を開く") {
                    onOpenKeyboardSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("再チェック") {
                    onRecheck()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
    }
}
