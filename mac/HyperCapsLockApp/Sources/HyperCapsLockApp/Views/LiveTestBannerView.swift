import HyperCapsLockCore
import SwiftUI

/// 今どのキー操作が検知・実行されているかをリアルタイムに表示するライブモニター。
struct LiveTestBannerView: View {
    let isEnabled: Bool
    let isAccessibilityTrusted: Bool
    let isTapRunning: Bool
    let isHoldingHyper: Bool
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
                    Text("HYPER 長押し中")
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
                    Text("— \(latest.detail)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("ここに押したキーの反応がリアルタイムで表示されます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        if !isEnabled { return .secondary }
        if !isAccessibilityTrusted || !isTapRunning { return .orange }
        if isHoldingHyper { return .blue }
        return .green
    }

    private var statusTitle: String {
        if !isEnabled { return "停止中（CapsLock は標準動作）" }
        if !isAccessibilityTrusted { return "アクセシビリティ権限の許可待ち" }
        if !isTapRunning { return "開始準備中..." }
        if isHoldingHyper { return "Hyper 待機中 — 次のキーを押してください" }
        return "稼働中 — CapsLock が使えます"
    }
}
