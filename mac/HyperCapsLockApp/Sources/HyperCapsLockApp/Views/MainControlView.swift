import HyperCapsLockCore
import SwiftUI

struct MainControlView: View {
    @Bindable var appState: AppState
    @State private var showOptionalFeatures = false
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                header
                LiveTestBannerView(appState: appState)
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if showsRuntimeIssues {
                        RuntimeIssueActionsView(appState: appState)
                    }

                    triggerSection
                    starterSection
                    editorSection
                    companionSoundSection
                    optionalFeaturesSection
                    advancedSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
            }
        }
        .frame(width: 540, height: 600)
    }

    private var header: some View {
        HStack {
            Text("Hyper CapsLock")
                .font(.title2.bold())

            Spacer()

            switch appState.runtimeStatus {
            case .restorationFailed:
                EmptyView()
            case .running, .waitingForInput:
                Button("一時停止", action: appState.stop)
            case .waitingForPermission:
                Button("アクセシビリティを許可", action: appState.requestAccessibilityPermission)
                    .buttonStyle(.borderedProminent)
            case .blocked, .stopped:
                if !appState.isAccessibilityTrusted {
                    Button("アクセシビリティを許可", action: appState.requestAccessibilityPermission)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("有効にする", action: appState.start)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var showsRuntimeIssues: Bool {
        switch appState.runtimeStatus {
        case .restorationFailed, .blocked: true
        default: !appState.runtimeIssues.isEmpty
        }
    }

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("トリガーキー")
                .font(.headline)
            TriggerSetupView(appState: appState)
            Text("キーや対象を変えると停止します。画面ロック、スリープ、アプリの再起動、キーボードの接続変更のあとも、状態を確認して有効にしてください。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var starterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("数字キーでアプリを切り替える", isOn: $appState.config.starterEnabled)
                .font(.headline)
                .toggleStyle(.switch)

            ShortcutAppPicker(appState: appState, slot: 1, target: $appState.config.slot1App)
            ShortcutAppPicker(appState: appState, slot: 2, target: $appState.config.slot2App)
            ShortcutAppPicker(appState: appState, slot: 3, target: $appState.config.slot3App)

            Button("アプリ一覧を再読み込み", action: appState.refreshInstalledApps)
                .controlSize(.small)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("エディタのショートカット")
                .font(.headline)

            Toggle(isOn: $appState.config.chatShortcutEnabled) {
                shortcutDescription(
                    "Cursor のチャット",
                    keys: "C",
                    detail: "Cursor が前面なら Command + L を送ります。それ以外では \(appState.config.slot1App.name) を前面にします。"
                )
            }
            .toggleStyle(.switch)
            .accessibilityLabel("Cursor のチャット（C）")
            .accessibilityHint("Cursor に Command + L を送ります。それ以外のアプリでは、1 番のアプリを前面にします。")

            Toggle(isOn: $appState.config.panelShortcutEnabled) {
                shortcutDescription(
                    "エディタのパネル",
                    keys: "T",
                    detail: "Cursor または VS Code が前面のときだけ Command + J を送ります。"
                )
            }
            .toggleStyle(.switch)
            .accessibilityLabel("エディタのパネル（T）")
            .accessibilityHint("Cursor または VS Code に Command + J を送ります。")
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var companionSoundSection: some View {
        HStack(spacing: 12) {
            Image(systemName: appState.config.companionSoundEnabled ? "waveform.circle.fill" : "speaker.slash.circle")
                .font(.title3)
                .foregroundStyle(appState.config.companionSoundEnabled ? Color.accentColor : Color.secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("相棒の声")
                    .font(.subheadline.weight(.semibold))
                Text("キー変換中に \(appState.config.triggerMode.keyInstructionName) を押すと鳴ります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                appState.previewCompanionSound()
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("相棒の声を試聴する")
            .accessibilityLabel("相棒の声を試聴する")

            Toggle("相棒の声を有効にする", isOn: $appState.config.companionSoundEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var optionalFeaturesSection: some View {
        DisclosureGroup("移動とウィンドウ", isExpanded: $showOptionalFeatures) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $appState.config.windowSplitEnabled) {
                    shortcutDescription("ウィンドウの左右分割", keys: "Q / W", detail: "Q で左半分、W で右半分に配置します。")
                }
                .toggleStyle(.switch)

                Toggle(isOn: $appState.config.navigationEnabled) {
                    shortcutDescription(
                        "カーソルの移動",
                        keys: "H / J / K / L / A / E / B / F",
                        detail: "H・J・K・L で左・下・上・右。A・E で行頭と行末、B・F で前後の単語に移動します。"
                    )
                }
                .toggleStyle(.switch)
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var advancedSection: some View {
        DisclosureGroup("詳細設定", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("単押しと長押しの境目")
                    Spacer()
                    Stepper(
                        "\(appState.config.tapThresholdMs) ミリ秒",
                        value: $appState.config.tapThresholdMs,
                        in: 120...350,
                        step: 20
                    )
                }
                .font(.subheadline)

                Toggle("ログイン時にアプリを開く", isOn: $appState.config.launchAtLogin)
                    .font(.subheadline)

                Toggle(isOn: $appState.config.passthroughUnassignedAsFourModifiers) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("未割り当てキーを他アプリへ渡す")
                            .font(.subheadline)
                        Text("オンでは未割り当てキーに Command・Control・Option・Shift を付けて送ります。オフでは押したキーの出力を止めます。割り当て済みのショートカットが優先され、ピリオドは設定にかかわらず出力を止めます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)

                Divider()

                Button("初回ガイドを開く", action: appState.reopenOnboarding)
                    .controlSize(.small)
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func shortcutDescription(_ title: String, keys: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            KeyComboView(trigger: appState.config.triggerMode, key: keys)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
