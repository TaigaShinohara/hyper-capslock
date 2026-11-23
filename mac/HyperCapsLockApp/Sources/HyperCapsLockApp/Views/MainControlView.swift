import HyperCapsLockCore
import SwiftUI

/// メイン設定＆動作確認画面。
struct MainControlView: View {
    @Bindable var appState: AppState
    @State private var showAdvanced = false
    @State private var showOptional = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if let banner = appState.statusBannerMessage {
                    Text(banner)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if !appState.runtimeIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(appState.runtimeIssues) { issue in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.title)
                                    .font(.headline)
                                Text(issue.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack {
                            Button("再試行") {
                                appState.retryRuntime()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("標準に戻す") {
                                appState.emergencyResetCapsLock()
                            }
                            .buttonStyle(.bordered)

                            Button("手順を見る") {
                                appState.openSetupGuide()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                }

                if !appState.capsLockConflicts.isEmpty {
                    ModifierConflictWarningCard(
                        conflicts: appState.capsLockConflicts,
                        onOpenKeyboardSettings: { appState.openKeyboardModifierSettings() },
                        onRecheck: { appState.recheckSystemModifiersAndRuntime() }
                    )
                }

                LiveTestBannerView(
                    isEnabled: appState.config.isEnabled,
                    isAccessibilityTrusted: appState.isAccessibilityTrusted,
                    isTapRunning: appState.isTapRunning,
                    isHidutilApplied: appState.isHidutilApplied,
                    isHoldingHyper: appState.isHoldingHyper,
                    hasModifierConflict: !appState.capsLockConflicts.isEmpty,
                    jisEisuuEnabled: appState.config.jisEisuuEnabled,
                    modifierHintText: appState.modifierHintText,
                    recentFeedbacks: appState.recentFeedbacks
                )

                starterSection
                optionalFeaturesSection
                advancedSection
            }
            .padding(20)
        }
        .frame(width: 580, height: 640)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ハイパーCapsLock")
                    .font(.title2.bold())
                Text("CapsLock を押すと Esc。押したまま次のキーで往復")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("有効にする", isOn: $appState.config.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private var starterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("基本")
                    .font(.headline)
                Spacer()
                Toggle("使う", isOn: $appState.config.starterEnabled)
                    .toggleStyle(.switch)
            }

            VStack(spacing: 10) {
                appPickerRow(slotTitle: "Hyper + 1（エディタ）", selection: $appState.config.slot1App)
                appPickerRow(slotTitle: "Hyper + 2（プレビュー）", selection: $appState.config.slot2App)
                appPickerRow(slotTitle: "Hyper + 3（ターミナル）", selection: $appState.config.slot3App)
            }
            .disabled(!appState.config.starterEnabled)
            .opacity(appState.config.starterEnabled ? 1.0 : 0.55)

            HStack(spacing: 16) {
                Label("C：チャット", systemImage: "bubble.left.and.bubble.right")
                Spacer()
                Label("T：パネル", systemImage: "rectangle.bottomthird.inset.filled")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func appPickerRow(slotTitle: String, selection: Binding<AppTarget>) -> some View {
        HStack {
            Image(nsImage: appState.appIcon(for: selection.wrappedValue))
                .resizable()
                .frame(width: 22, height: 22)

            Text(slotTitle)
                .font(.subheadline)
                .frame(width: 185, alignment: .leading)

            Picker("", selection: selection) {
                let choices = pickerChoices(including: selection.wrappedValue)
                ForEach(choices, id: \.bundleIdentifier) { app in
                    Text(app.name).tag(app)
                }
            }
            .labelsHidden()
        }
    }

    private func pickerChoices(including current: AppTarget) -> [AppTarget] {
        var list = appState.installedApps
        if !list.contains(where: { $0.bundleIdentifier == current.bundleIdentifier }) {
            list.insert(current, at: 0)
        }
        return list
    }

    private var optionalFeaturesSection: some View {
        DisclosureGroup("あとから足す", isExpanded: $showOptional) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("ウィンドウ左右分割", isOn: $appState.config.windowSplitEnabled)
                Toggle("カーソル・単語移動", isOn: $appState.config.navigationEnabled)
                Toggle("JIS「英数」キー", isOn: $appState.config.jisEisuuEnabled)
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var advancedSection: some View {
        DisclosureGroup("詳細・安全設定", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("単押しと長押しの境界時間")
                    Spacer()
                    Stepper(
                        "\(appState.config.tapThresholdMs) ミリ秒",
                        value: $appState.config.tapThresholdMs,
                        in: 120...350,
                        step: 20
                    )
                }

                Toggle(isOn: $appState.config.passthroughUnassignedAsFourModifiers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("未割り当てキーを Cmd+Ctrl+Opt+Shift 付きで他アプリへ渡す（上級者向け）")
                        Text("OFF（推奨）のあいだは未割り当てキーによる誤終了（Cmd+Q 等）を防ぎます。Hyper+. は常にブロックされます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Mac へのログイン時に自動で起動する", isOn: $appState.config.launchAtLogin)

                Divider()

                HStack {
                    Button("初回ガイドをもう一度開く") {
                        appState.reopenOnboarding()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("アプリ一覧を再読み込み") {
                        appState.refreshInstalledApps()
                    }
                    .buttonStyle(.bordered)

                    Button("CapsLock を標準に戻して停止", role: .destructive) {
                        appState.emergencyResetCapsLock()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
