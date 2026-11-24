import HyperCapsLockCore
import SwiftUI

/// 初心者向けの 3 ステップ初期セットアップ画面。
struct OnboardingView: View {
    @Bindable var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Hyper CapsLock")
                .font(.title3.bold())

            stepIndicator

            Divider()

            Group {
                switch appState.config.onboardingStep {
                case .permissions:
                    step1PermissionsView
                case .testEsc:
                    step2TestEscView
                case .starter, .completed:
                    step3StarterView
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: appState.config.onboardingStep)

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(width: 480, height: 470)
    }

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            stepBadge(
                number: 1,
                title: "権限",
                active: appState.config.onboardingStep == .permissions,
                done: appState.isAccessibilityTrusted
            )
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            stepBadge(
                number: 2,
                title: "Esc 確認",
                active: appState.config.onboardingStep == .testEsc,
                done: appState.config.onboardingStep == .starter || appState.config.onboardingStep == .completed
            )
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            stepBadge(
                number: 3,
                title: "往復",
                active: appState.config.onboardingStep == .starter,
                done: appState.config.onboardingStep == .completed
            )
        }
    }

    private func stepBadge(number: Int, title: String, active: Bool, done: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle.fill")
                .foregroundStyle(done ? .green : (active ? Color.accentColor : .secondary))
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active || done ? .primary : .secondary)
        }
    }

    // MARK: - Step 1: Permissions

    private var step1PermissionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("アクセシビリティを許可")
                .font(.headline)

            Text("キー変換のために必要です。外部通信は行いません。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("下のボタンでシステム設定を開く", systemImage: "1.circle")
                Label("「Hyper CapsLock」を ON にする", systemImage: "2.circle")
                Label("自動で次のステップへ進みます", systemImage: "3.circle")
            }
            .font(.subheadline)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("システム設定を開く") {
                    appState.requestAccessibilityPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()

                if appState.isAccessibilityTrusted {
                    Button("次へ") {
                        appState.advanceOnboarding(to: .testEsc)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Step 2: Test Esc

    private var step2TestEscView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CapsLock を 1 回押して離す")
                .font(.headline)

            VStack(spacing: 10) {
                if appState.escTestSuccessCount > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("Esc を検出しました")
                        .font(.headline)
                        .foregroundStyle(.green)
                } else {
                    KeyCapView(label: "CapsLock", highlighted: true)
                        .scaleEffect(1.25)
                        .padding(.vertical, 4)
                    Text("短く押すと Esc になります")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                appState.escTestSuccessCount > 0 ? Color.green.opacity(0.1) : Color.primary.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: appState.escTestSuccessCount > 0)

            if !appState.capsLockConflicts.isEmpty {
                ModifierConflictWarningCard(
                    conflicts: appState.capsLockConflicts,
                    onOpenKeyboardSettings: { appState.openKeyboardModifierSettings() },
                    onRecheck: { appState.recheckSystemModifiersAndRuntime() }
                )
            }

            HStack {
                Spacer()
                if appState.escTestSuccessCount > 0 {
                    Button("次へ") {
                        appState.advanceOnboarding(to: .starter)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("権限と設定を再確認") {
                        appState.recheckSystemModifiersAndRuntime()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Step 3: Starter

    private var step3StarterView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("押したままキーで切り替え")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    KeyComboView(key: "1")
                    Text(appState.config.slot1App.name)
                        .font(.subheadline)
                }
                GridRow {
                    KeyComboView(key: "2")
                    Text(appState.config.slot2App.name)
                        .font(.subheadline)
                }
                GridRow {
                    KeyComboView(key: "3")
                    Text(appState.config.slot3App.name)
                        .font(.subheadline)
                }
                GridRow {
                    KeyComboView(key: "C")
                    Text("チャット開閉")
                        .font(.subheadline)
                }
                GridRow {
                    KeyComboView(key: "T")
                    Text("下パネル開閉")
                        .font(.subheadline)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

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
                recentFeedbacks: appState.recentFeedbacks
            )

            HStack {
                Spacer()
                Button("始める") {
                    appState.advanceOnboarding(to: .completed)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
