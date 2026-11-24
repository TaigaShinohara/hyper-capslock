import HyperCapsLockCore
import SwiftUI

/// 押したキーの反応をリアルタイムに示すコンパクトなライブモニター。
struct LiveTestBannerView: View {
    let isEnabled: Bool
    let isAccessibilityTrusted: Bool
    let isTapRunning: Bool
    let isHoldingHyper: Bool
    let hasModifierConflict: Bool
    let jisEisuuEnabled: Bool
    let recentFeedbacks: [HyperFeedbackEvent]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let secondary = secondaryText {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            KeyCapView(label: isHoldingHyper ? "HYPER" : "Caps", highlighted: isHoldingHyper)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHoldingHyper)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: recentFeedbacks.first?.id)
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        if !isEnabled { return .secondary }
        if !isAccessibilityTrusted || !isTapRunning || hasModifierConflict { return .orange }
        if isHoldingHyper { return .accentColor }
        return .green
    }

    private var primaryText: String {
        if !isEnabled { return "一時停止中" }
        if !isAccessibilityTrusted { return "権限の許可待ち" }
        if !isTapRunning { return "準備中..." }
        if isHoldingHyper { return "次のキーを押してください" }
        if let latest = recentFeedbacks.first {
            return latest.summary
        }
        if hasModifierConflict {
            return jisEisuuEnabled ? "英数キーで稼働中" : "修飾キー設定を確認"
        }
        return "稼働中"
    }

    private var secondaryText: String? {
        if !isEnabled { return "CapsLock は標準動作" }
        if !isAccessibilityTrusted || !isTapRunning { return nil }
        if isHoldingHyper { return "長押し中" }
        if let latest = recentFeedbacks.first {
            return latest.detail
        }
        return "CapsLock を押すと反応を表示"
    }
}
