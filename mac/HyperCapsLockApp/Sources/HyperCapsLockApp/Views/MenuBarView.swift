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

            Button(appState.config.isEnabled ? "Hyper CapsLock を一時停止" : "Hyper CapsLock を再開") {
                appState.toggleEnabled()
            }

            Button("設定・動作確認ウィンドウを開く") {
                openMainWindow()
            }

            if !appState.isAccessibilityTrusted {
                Button("アクセシビリティ権限を許可する...") {
                    appState.requestAccessibilityPermission()
                }
            }

            Divider()

            Button("CapsLock を標準に戻して終了") {
                appState.quitAndRestore()
            }
        }
    }

    private var statusSummary: String {
        if !appState.config.isEnabled { return "状態: 一時停止中（標準 CapsLock）" }
        if !appState.isAccessibilityTrusted { return "状態: 権限の許可待ち" }
        return appState.isTapRunning ? "状態: 稼働中" : "状態: 準備中"
    }
}
