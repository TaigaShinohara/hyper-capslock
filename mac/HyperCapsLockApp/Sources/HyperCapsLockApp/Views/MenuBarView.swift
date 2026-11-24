import SwiftUI

/// メニューバー常駐メニューの内容。
struct MenuBarView: View {
    @Bindable var appState: AppState
    let openMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statusSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button(appState.config.isEnabled ? "一時停止" : "再開") {
                appState.toggleEnabled()
            }

            Button("設定を開く") {
                openMainWindow()
            }

            if !appState.isAccessibilityTrusted {
                Button("アクセシビリティを許可...") {
                    appState.requestAccessibilityPermission()
                }
            }

            Divider()

            Button("標準に戻して終了") {
                appState.quitAndRestore()
            }
        }
    }

    private var statusSummary: String {
        if !appState.config.isEnabled { return "一時停止中" }
        if !appState.isAccessibilityTrusted { return "権限待ち" }
        return appState.isTapRunning ? "稼働中" : "準備中"
    }
}
