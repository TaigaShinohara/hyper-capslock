import HyperCapsLockCore
import SwiftUI

/// 初心者向けの 3 ステップ初期セットアップ画面。
struct OnboardingView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView

            stepIndicator

            Divider()

            switch appState.config.onboardingStep {
            case .permissions:
                step1PermissionsView
            case .testEsc:
                step2TestEscView
            case .starter, .completed:
                step3StarterView
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 560, height: 520)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hyper CapsLock へようこそ")
                .font(.title2.bold())
            Text("CapsLock の単押しを Esc、長押しを AI 開発用ショートカットに変えます。3 ステップですぐに使えます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 12) {
            stepBadge(number: 1, title: "権限を許可", active: appState.config.onboardingStep == .permissions, done: appState.isAccessibilityTrusted)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            stepBadge(number: 2, title: "Esc を試す", active: appState.config.onboardingStep == .testEsc, done: appState.config.onboardingStep == .starter || appState.config.onboardingStep == .completed)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            stepBadge(number: 3, title: "往復を ON", active: appState.config.onboardingStep == .starter, done: appState.config.onboardingStep == .completed)
        }
    }

    private func stepBadge(number: Int, title: String, active: Bool, done: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle.fill")
                .foregroundStyle(done ? .green : (active ? Color.accentColor : .secondary))
            Text(title)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active || done ? .primary : .secondary)
        }
    }

    // MARK: - Step 1: Permissions

    private var step1PermissionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ステップ 1：macOS のアクセシビリティ権限を許可する")
                .font(.headline)

            Text("キー操作の変換とウィンドウ配置を行うため、このアプリにアクセシビリティ権限が必要です。外部への通信は一切行いません。")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("下のボタンを押すと「システム設定」が開きます", systemImage: "1.circle")
                Label("一覧の「Hyper CapsLock」のスイッチを ON にしてください", systemImage: "2.circle")
                Label("許可すると自動的に次のステップへ進みます", systemImage: "3.circle")
            }
            .font(.subheadline)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("システム設定を開いて許可する") {
                    appState.requestAccessibilityPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()

                if appState.isAccessibilityTrusted {
                    Button("次へ進む") {
                        appState.advanceOnboarding(to: .testEsc)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Step 2: Test Esc

    private var step2TestEscView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ステップ 2：最初の成功 — CapsLock をポンと押してすぐ離す")
                .font(.headline)

            Text("まずは単押しが Esc になり、大文字固定（LED 点灯）にならないことを確かめます。")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                if appState.escTestSuccessCount > 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("成功！Esc を \(appState.escTestSuccessCount) 回検出しました")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text("大文字固定にならずに Esc として動いています。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "keyboard")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.accentColor)
                    Text("今すぐキーボードの CapsLock を 1 回ポンと押してみてください")
                        .font(.headline)
                    Text("（200ミリ秒以内に離すと Esc になります）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                (appState.escTestSuccessCount > 0 ? Color.green.opacity(0.1) : Color.secondary.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: 12)
            )

            LiveTestBannerView(
                isEnabled: appState.config.isEnabled,
                isAccessibilityTrusted: appState.isAccessibilityTrusted,
                isTapRunning: appState.isTapRunning,
                isHoldingHyper: appState.isHoldingHyper,
                recentFeedbacks: appState.recentFeedbacks
            )

            HStack {
                Spacer()
                Button(appState.escTestSuccessCount > 0 ? "次へ：往復ショートカットを設定" : "テストをスキップして次へ") {
                    appState.advanceOnboarding(to: .starter)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Step 3: Starter

    private var step3StarterView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ステップ 3：往復ショートカットを試す")
                .font(.headline)

            Text("CapsLock を押したまま以下のキーを押すと、アプリやチャットを切り替えられます。お使いの Mac から候補を自動選択しました。")
                .font(.callout)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    Text("CapsLock + 1").font(.system(.body, design: .monospaced).bold())
                    Text(appState.config.slot1App.name)
                }
                GridRow {
                    Text("CapsLock + 2").font(.system(.body, design: .monospaced).bold())
                    Text(appState.config.slot2App.name)
                }
                GridRow {
                    Text("CapsLock + 3").font(.system(.body, design: .monospaced).bold())
                    Text(appState.config.slot3App.name)
                }
                GridRow {
                    Text("CapsLock + C").font(.system(.body, design: .monospaced).bold())
                    Text("Cursor チャット欄を開く／Cursor へ移動")
                }
                GridRow {
                    Text("CapsLock + T").font(.system(.body, design: .monospaced).bold())
                    Text("エディタ下のパネルを開閉")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))

            LiveTestBannerView(
                isEnabled: appState.config.isEnabled,
                isAccessibilityTrusted: appState.isAccessibilityTrusted,
                isTapRunning: appState.isTapRunning,
                isHoldingHyper: appState.isHoldingHyper,
                recentFeedbacks: appState.recentFeedbacks
            )

            HStack {
                Text("ウィンドウ左右分割や矢印移動は、次の画面でいつでも追加できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("完了して設定画面へ") {
                    appState.advanceOnboarding(to: .completed)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
