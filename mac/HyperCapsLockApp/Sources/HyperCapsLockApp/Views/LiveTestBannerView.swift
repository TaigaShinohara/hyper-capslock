import HyperCapsLockCore
import SwiftUI

/// 今どのキー操作が検知・実行されているかをリアルタイムに表示するライブモニター。
struct LiveTestBannerView: View {
    let isEnabled: Bool
    let isAccessibilityTrusted: Bool
    let isTapRunning: Bool
    let isHidutilApplied: Bool
    let isHoldingHyper: Bool
    let hasModifierConflict: Bool
    let jisEisuuEnabled: Bool
    let modifierHintText: String?
    let recentFeedbacks: [HyperFeedbackEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(statusTitle)
                    .font(.headline)

                Spacer()

                if isHoldingHyper {
                    Text("CapsLock 長押し中")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.18), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }

            if let latest = recentFeedbacks.first {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(latest.summary)
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }

            if let hint = modifierHintText {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        if !isEnabled { return .secondary }
        if !isAccessibilityTrusted || !isTapRunning { return .orange }
        if !isHidutilApplied { return .orange }
        if isHoldingHyper { return .blue }
        if hasModifierConflict { return .orange }
        return .green
    }

    private var statusTitle: String {
        if !isEnabled { return "停止中（CapsLock は標準動作）" }
        if !isAccessibilityTrusted { return "アクセシビリティ権限の許可待ち" }
        if !isTapRunning { return "開始準備中..." }
        if !isHidutilApplied { return "キー監視中（CapsLock の変換に失敗）" }
        if isHoldingHyper { return "次のキーを待っています" }
        if hasModifierConflict {
            return jisEisuuEnabled
                ? "稼働中（修飾キー設定により CapsLock は無効・英数キーは有効）"
                : "稼働中（システム設定の修飾キーと競合中）"
        }
        return "稼働中 — CapsLock が使えます"
    }
}
