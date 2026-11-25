import HyperCapsLockCore
import SwiftUI

struct MenuBarView: View {
    var appState: AppState
    let openMainWindow: () -> Void

    var body: some View {
        Text("\(appState.runtimeStatus.title) · \(appState.config.triggerMode.title)")
        Divider()

        switch appState.runtimeStatus {
        case .running, .waitingForInput:
            Button("一時停止", action: appState.stop)
        case .restorationFailed:
            Button("復元を再試行", action: appState.stop)
        case .stopped, .blocked:
            if appState.canResumeFromMenu {
                Button("再開", action: appState.resumeFromMenu)
            }
        case .waitingForPermission:
            EmptyView()
        }

        Button(appState.config.onboardingStep == .completed ? "設定を開く" : "セットアップを開く", action: openMainWindow)

        if !appState.isAccessibilityTrusted {
            Button("アクセシビリティを許可…", action: appState.requestAccessibilityPermission)
        }

        Divider()

        Button("停止して終了", action: appState.quitAndRestore)
    }
}
