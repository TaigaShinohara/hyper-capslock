import HyperCapsLockCore
import SwiftUI

/// メイン設定＆動作確認画面。
struct MainControlView: View {
    @Bindable var appState: AppState
    @State private var showOptionalFeatures = false
    @State private var showAdvanced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerRow

                if let banner = appState.statusBannerMessage {
                    statusBanner(banner)
                }

                if !appState.runtimeIssues.isEmpty {
                    runtimeIssuesCard
                } else if !appState.isAccessibilityTrusted {
                    permissionWarningCard
                }

                if !appState.capsLockConflicts.isEmpty {
                    ModifierConflictWarningCard(
                        conflicts: appState.capsLockConflicts,
                        onOpenKeyboardSettings: { appState.openKeyboardModifierSettings() },
                        onRecheck: { appState.recheckSystemModifiersAndRuntime() }
                    )
                }

                if appState.isAccessibilityTrusted {
                    LiveTestBannerView(
                        isEnabled: appState.config.isEnabled,
                        isAccessibilityTrusted: appState.isAccessibilityTrusted,
                        isTapRunning: appState.isTapRunning,
                        isHidutilApplied: appState.isHidutilApplied,
                        isHoldingHyper: appState.isHoldingHyper,
                        hasModifierConflict: !appState.capsLockConflicts.isEmpty,
                        jisEisuuEnabled: appState.config.jisEisuuEnabled,
                        recentFeedbacks: appState.recentFeedbacks
                    )
                }

                starterSection
                optionalFeaturesSection
                advancedSection
            }
            .padding(18)
        }
        .frame(width: 480, height: 520)
    }

    private var headerRow: some View {
        HStack {
            Text("Hyper CapsLock")
                .font(.title3.bold())

            Spacer()

            Toggle("Hyper CapsLock を有効にする", isOn: $appState.config.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.caption)
            Spacer()
            Button {
                appState.statusBannerMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("通知を閉じる")
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var runtimeIssuesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(appState.runtimeIssues) { issue in
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.title)
                        .font(.subheadline.weight(.semibold))
                    Text(issue.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Button("再試行") {
                    appState.retryRuntime()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("標準に戻す") {
                    appState.emergencyResetCapsLock()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("手順を見る") {
                    appState.openSetupGuide()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }

    private var permissionWarningCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("アクセシビリティ権限が必要です")
                    .font(.subheadline.weight(.semibold))
                Text("システム設定で許可すると自動で稼働します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("許可を開く") {
                appState.requestAccessibilityPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var starterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("往復ショートカット")
                    .font(.headline)
                Spacer()
                Toggle("往復ショートカットを有効にする", isOn: $appState.config.starterEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            VStack(spacing: 8) {
                appPickerRow(key: "1", role: "エディタ", selection: $appState.config.slot1App)
                appPickerRow(key: "2", role: "プレビュー", selection: $appState.config.slot2App)
                appPickerRow(key: "3", role: "ターミナル", selection: $appState.config.slot3App)
            }
            .disabled(!appState.config.starterEnabled)
            .opacity(appState.config.starterEnabled ? 1.0 : 0.5)

            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    KeyComboView(key: "C")
                    Text("チャット")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    KeyComboView(key: "T")
                    Text("下パネル")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    KeyCapView(label: "単押し")
                    Text("Esc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(appState.config.starterEnabled ? 1.0 : 0.5)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func appPickerRow(key: String, role: String, selection: Binding<AppTarget>) -> some View {
        HStack(spacing: 10) {
            KeyComboView(key: key)
                .frame(width: 82, alignment: .leading)

            Image(nsImage: appState.appIcon(for: selection.wrappedValue))
                .resizable()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            Picker(role, selection: selection) {
                let choices = pickerChoices(including: selection.wrappedValue)
                ForEach(choices, id: \.bundleIdentifier) { app in
                    Text(app.name).tag(app)
                }
            }
            .labelsHidden()
            .accessibilityLabel("\(role)（CapsLock と \(key)）")
        }
    }

    private func pickerChoices(including current: AppTarget) -> [AppTarget] {
        var list = appState.installedApps
        if !list.contains(where: { $0.bundleIdentifier == current.bundleIdentifier }) {
            list.insert(current, at: 0)
        }
        return list
    }

    private var enabledOptionalCount: Int {
        [
            appState.config.windowSplitEnabled,
            appState.config.navigationEnabled,
            appState.config.jisEisuuEnabled,
        ].filter { $0 }.count
    }

    private var optionalFeaturesSection: some View {
        DisclosureGroup(isExpanded: $showOptionalFeatures) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $appState.config.windowSplitEnabled) {
                    HStack(spacing: 8) {
                        Text("ウィンドウ左右分割")
                            .font(.subheadline)
                        KeyCapView(label: "Q / W")
                    }
                }

                Toggle(isOn: $appState.config.navigationEnabled) {
                    HStack(spacing: 8) {
                        Text("カーソル移動")
                            .font(.subheadline)
                        KeyCapView(label: "H J K L")
                    }
                }

                Toggle(isOn: $appState.config.jisEisuuEnabled) {
                    Text("JIS「英数」キーも Hyper にする")
                        .font(.subheadline)
                }
            }
            .padding(.top, 10)
        } label: {
            HStack {
                Text("追加機能")
                    .font(.headline)
                Spacer()
                if enabledOptionalCount > 0 {
                    Text("\(enabledOptionalCount) 件 ON")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var advancedSection: some View {
        DisclosureGroup("詳細設定", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("長押し判定")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        "\(appState.config.tapThresholdMs) ミリ秒",
                        value: $appState.config.tapThresholdMs,
                        in: 120...350,
                        step: 20
                    )
                    .font(.subheadline)
                }

                Toggle("ログイン時に自動起動", isOn: $appState.config.launchAtLogin)
                    .font(.subheadline)

                Toggle(isOn: $appState.config.passthroughUnassignedAsFourModifiers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("未割り当てキーを他アプリへ渡す")
                            .font(.subheadline)
                        Text("OFF 推奨（誤終了を防止）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 8) {
                    Button("初回ガイド") {
                        appState.reopenOnboarding()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("アプリ再読込") {
                        appState.refreshInstalledApps()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    Button("標準に戻して停止", role: .destructive) {
                        appState.emergencyResetCapsLock()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.top, 10)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}
