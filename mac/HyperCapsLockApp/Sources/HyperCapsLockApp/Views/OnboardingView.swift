import HyperCapsLockCore
import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    KeyMarkView()
                    Text("Hyper CapsLock")
                        .font(.title2.bold())
                }
                stepIndicator
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch appState.config.onboardingStep {
                    case .permissions:
                        selectionStep
                    case .testEsc:
                        testStep
                    case .starter, .completed:
                        starterStep
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }

            Divider()

            footer
                .padding(20)
        }
        .frame(width: 540, height: 600)
        .tint(AppTheme.teal)
    }

    private var stepIndicator: some View {
        let label: String
        switch appState.config.onboardingStep {
        case .permissions: label = "1 / 3　キーの選択"
        case .testEsc: label = "2 / 3　Esc の確認"
        case .starter, .completed: label = "3 / 3　数字ショートカット（任意）"
        }
        return Text(label)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var selectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("どのキーを使いますか？")
                .font(.headline)
            TriggerSetupView(appState: appState)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                if appState.isAccessibilityTrusted {
                    Label("アクセシビリティは許可済みです", systemImage: "checkmark.circle")
                    Text("「有効にして試す」を選ぶとキー変換が始まります。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("アクセシビリティを許可")
                        .font(.headline)
                    Text("キー変換に必要です。システム設定で「Hyper CapsLock」を許可してから、有効にして試せます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            switch appState.runtimeStatus {
            case .blocked, .restorationFailed:
                LiveTestBannerView(appState: appState)
                RuntimeIssueActionsView(appState: appState)
            default:
                if !appState.runtimeIssues.isEmpty {
                    RuntimeIssueActionsView(appState: appState)
                }
            }
        }
    }

    private var testStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("単押しで Esc になるか確認")
                .font(.headline)

            switch appState.runtimeStatus {
            case .running where appState.isTriggerVerified:
                Label("Esc の反応を確認しました", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.teal)
            case .waitingForInput, .running:
                VStack(alignment: .leading, spacing: 8) {
                    KeyCapView(label: appState.config.triggerMode.keyInstructionName, highlighted: true)
                    Text("選んだキーを 1 回、短く押して離してください。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DisclosureGroup("反応しないとき") {
                        Text("Karabiner、Raycast、キーボード本体の設定で、そのキーが別の動作に割り当てられていないか確認してください。別のキーを試すには「キー選択に戻る」を選びます。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                    }
                }
            default:
                EmptyView()
            }

            LiveTestBannerView(appState: appState)
            RuntimeIssueActionsView(appState: appState)
        }
    }

    private var starterStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("数字キーでアプリに切り替える")
                .font(.headline)

            Text("試用は 1 キーで行います。数字ショートカットを有効にすると、トリガーキーを押したまま 1・2・3 を押してアプリを切り替えられます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ShortcutAppPicker(appState: appState, slot: 1, target: $appState.config.slot1App)
                .disabled(appState.isStarterTrialEnabled)

            if appState.isStarterTrialEnabled, trialIsReady {
                if appState.isStarterTestVerified {
                    Label("\(appState.config.slot1App.name) が前面にあることを確認しました", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\(appState.config.triggerMode.keyInstructionName) を押したまま 1 を押します。\(appState.config.slot1App.name) が開いたら、この画面に戻ってください。")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("試すアプリを選び直す") {
                        appState.resetStarterTrial()
                        appState.refreshInstalledApps()
                    }
                }
            }

            LiveTestBannerView(appState: appState)
            RuntimeIssueActionsView(appState: appState)
        }
    }

    private var footer: some View {
        VStack(alignment: .trailing, spacing: 10) {
            switch appState.config.onboardingStep {
            case .permissions:
                HStack {
                    Button("有効にせず設定を開く", action: openInactiveSettings)
                    Spacer()
                    if appState.isAccessibilityTrusted {
                        Button("有効にして試す", action: appState.startTrial)
                            .buttonStyle(.borderedProminent)
                            .disabled(!canStartTrial)
                    } else {
                        Button("アクセシビリティを許可", action: appState.requestAccessibilityPermission)
                            .buttonStyle(.borderedProminent)
                    }
                }
            case .testEsc:
                HStack {
                    Button("キー選択に戻る", action: appState.restartTrialSetup)
                    Spacer()
                    Button("停止して設定を開く", action: openInactiveSettings)
                    if trialIsReady {
                        Button("次へ") {
                            appState.advanceOnboarding(to: .starter)
                        }
                        .buttonStyle(.borderedProminent)
                    } else if case .stopped = appState.runtimeStatus {
                        Button("有効にして試す", action: appState.startTrial)
                            .buttonStyle(.borderedProminent)
                    }
                }
            case .starter, .completed:
                HStack {
                    Button("キー選択に戻る", action: appState.restartTrialSetup)
                    Spacer()
                    if trialIsReady {
                        Button("数字キーの確認を省く", action: finishWithoutStarter)
                        if appState.isStarterTestVerified && appState.isStarterTrialEnabled {
                            Button("数字キーを有効にする") {
                                appState.finishOnboarding(keepEnabled: true)
                            }
                            .buttonStyle(.borderedProminent)
                        } else if !appState.isStarterTrialEnabled {
                            Button("数字キーを試す", action: appState.enableStarterTrial)
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Button("停止して設定を開く", action: openInactiveSettings)
                    }
                }
            }
        }
    }

    private var canStartTrial: Bool {
        if case .restorationFailed = appState.runtimeStatus { return false }
        return !appState.config.triggerMode.usesCapsLock || (
            appState.selectedKeyboardID != nil &&
            appState.capsLockSetupIssue == nil &&
            appState.capsLockConflicts.isEmpty
        )
    }

    private var trialIsReady: Bool {
        appState.isTriggerVerified && appState.runtimeStatus.isOperational
    }

    private func openInactiveSettings() {
        appState.finishOnboarding(keepEnabled: false)
    }

    private func finishWithoutStarter() {
        appState.finishOnboarding(keepEnabled: true, keepStarter: false)
    }
}
