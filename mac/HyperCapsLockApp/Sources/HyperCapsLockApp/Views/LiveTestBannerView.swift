import HyperCapsLockCore
import SwiftUI

struct LiveTestBannerView: View {
    var appState: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .padding(.top, 5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(appState.runtimeStatus.title) · \(appState.config.triggerMode.title)")
                    .font(.subheadline.weight(.semibold))
                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .cockpitCardSurface()
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch appState.runtimeStatus {
        case .running: AppTheme.teal
        case .waitingForPermission, .waitingForInput, .blocked: AppTheme.orange
        case .restorationFailed: .red
        case .stopped: .secondary
        }
    }

    private var description: String? {
        let status = appState.runtimeStatus
        switch status {
        case .running:
            if appState.isHoldingHyper {
                return "トリガーキーを長押し中。組み合わせるキーを押せます。"
            }
            if let feedback = appState.recentFeedbacks.first {
                return "\(feedback.summary)（\(feedback.detail)）"
            }
            return "トリガーキーを短く押すと Esc。押したまま別のキーでショートカットを使えます。"
        case .waitingForInput, .waitingForPermission, .stopped, .blocked, .restorationFailed:
            return status.detail
        }
    }
}

struct RuntimeIssueActionsView: View {
    var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(appState.runtimeIssues) { issue in
                VStack(alignment: .leading, spacing: 3) {
                    Text(issue.title)
                        .font(.subheadline.weight(.semibold))
                    Text(issue.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            switch appState.runtimeStatus {
            case .restorationFailed:
                HStack {
                    Button("復元を再試行", action: appState.stop)
                    Button("キーボード設定を開く", action: appState.openKeyboardModifierSettings)
                    Button("手順を見る", action: appState.openSetupGuide)
                }
            case .waitingForPermission:
                Button("アクセシビリティを許可", action: appState.requestAccessibilityPermission)
            case .blocked:
                HStack {
                    Button("設定を再確認", action: appState.retryRuntime)
                    Button("手順を見る", action: appState.openSetupGuide)
                }
            default:
                if !appState.runtimeIssues.isEmpty {
                    Button("手順を見る", action: appState.openSetupGuide)
                }
            }
        }
    }
}
