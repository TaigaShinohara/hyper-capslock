import HyperCapsLockCore
import SwiftUI

/// メイン設定＆動作確認画面。
struct MainControlView: View {
    @Bindable var appState: AppState
    @State private var showAdvanced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if let banner = appState.statusBannerMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(banner)
                            .font(.callout)
                        Spacer()
                        Button("閉じる") {
                            appState.statusBannerMessage = nil
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }

                if !appState.isAccessibilityTrusted {
                    permissionWarningCard
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
                Text("Hyper CapsLock")
                    .font(.title2.bold())
                Text("単押しは Esc、押したままで AI 開発コックピット")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("有効にする", isOn: $appState.config.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()

            Text(appState.config.isEnabled ? "ON" : "OFF")
                .font(.headline)
                .foregroundStyle(appState.config.isEnabled ? .green : .secondary)
                .frame(width: 34, alignment: .leading)
        }
    }

    private var permissionWarningCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("アクセシビリティ権限が必要です")
                    .font(.headline)
                Text("システム設定で「Hyper CapsLock」を許可すると自動で稼働します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("許可を開く") {
                appState.requestAccessibilityPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var starterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("1. 基本と往復（スターター）")
                    .font(.headline)
                Spacer()
                Toggle("スターターを有効", isOn: $appState.config.starterEnabled)
                    .toggleStyle(.switch)
            }

            Text("割り当て表：`Hyper+1` エディタ → `Hyper+C` チャット → `Enter` で送信 → `Hyper+2` プレビュー（または `Hyper+T` パネル）")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 10) {
                appPickerRow(slotTitle: "Hyper + 1（エディタ）", selection: $appState.config.slot1App)
                appPickerRow(slotTitle: "Hyper + 2（プレビュー）", selection: $appState.config.slot2App)
                appPickerRow(slotTitle: "Hyper + 3（ターミナル）", selection: $appState.config.slot3App)
            }
            .disabled(!appState.config.starterEnabled)
            .opacity(appState.config.starterEnabled ? 1.0 : 0.55)

            Divider()

            HStack(spacing: 16) {
                Label("Hyper + C：Cursor チャット開閉（別アプリ時は Cursor を前面へ）", systemImage: "bubble.left.and.bubble.right")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("Hyper + T：Cursor / VS Code の下パネル開閉", systemImage: "rectangle.bottomthird.inset.filled")
                Spacer()
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
        VStack(alignment: .leading, spacing: 12) {
            Text("2. あとから 1 個ずつ足す機能")
                .font(.headline)

            Toggle(isOn: $appState.config.windowSplitEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ウィンドウ左右分割（Hyper + Q で左半分 / Hyper + W で右半分）")
                        .font(.subheadline)
                    Text("Raycast なしでも動作します。OFF のあいだは Q / W の誤動作を防ぎます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(isOn: $appState.config.navigationEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("第 2 弾：カーソル・単語移動（H/J/K/L 矢印、A/E 行頭行末、B/F 単語）")
                        .font(.subheadline)
                    Text("ホームポジションから手を動かさずにカーソルを動かせます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(isOn: $appState.config.jisEisuuEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JIS キーボードの「英数」キーも Hyper にする")
                        .font(.subheadline)
                    Text("スペース左の英数キーでも単押し Esc・長押し Hyper が使えます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
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
