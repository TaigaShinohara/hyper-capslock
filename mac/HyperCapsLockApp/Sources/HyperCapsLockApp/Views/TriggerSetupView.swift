import HyperCapsLockCore
import SwiftUI

struct TriggerSetupView: View {
    var appState: AppState
    @State private var showsCapsLockDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("トリガーキー", selection: Binding(
                get: { appState.config.triggerMode },
                set: { appState.setTriggerMode($0) }
            )) {
                Text(HyperTriggerMode.capsLock.title).tag(HyperTriggerMode.capsLock)
                Text("JIS 英数").tag(HyperTriggerMode.eisuu)
                if appState.config.triggerMode == .capsLockAndEisuu {
                    Text(HyperTriggerMode.capsLockAndEisuu.title).tag(HyperTriggerMode.capsLockAndEisuu)
                }
            }
            .pickerStyle(.segmented)

            if appState.config.triggerMode.usesEisuu {
                Text("JIS キーボードの「英数」は、入力ソースの切り替えに代わって、単押しで Esc、長押しでショートカットになります。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if appState.config.triggerMode.usesCapsLock {
                capsLockSetup
            }
        }
    }

    private var connectedSelection: UInt64? {
        appState.capsLockKeyboards.first { $0.id == appState.selectedKeyboardID }?.id
    }

    private var capsLockSetup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選んだキーボードの CapsLock は単押しで Esc、長押しでショートカットになります。変換に \(appState.config.capsLockReservedKey.title) を使います。有効中は、どのキーボードでもこのファンクションキーを直接押すと Hyper として扱います。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if appState.capsLockKeyboards.count > 1 ||
                (appState.capsLockKeyboards.count == 1 && connectedSelection == nil) {
                Picker("対象キーボード", selection: Binding(
                    get: { connectedSelection },
                    set: { id in
                        if let id {
                            appState.selectKeyboard(id)
                        }
                    }
                )) {
                    if connectedSelection == nil {
                        Text("キーボードを選択").tag(nil as UInt64?)
                    }
                    ForEach(appState.capsLockKeyboards, id: \.id) { keyboard in
                        Text(keyboard.name).tag(Optional(keyboard.id))
                    }
                }
            } else if let keyboard = appState.capsLockKeyboards.first {
                LabeledContent("対象キーボード", value: keyboard.name)
                    .font(.subheadline)
            }

            DisclosureGroup("予約キーと競合の確認", isExpanded: $showsCapsLockDetails) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("CapsLock の予約キー", selection: Binding(
                        get: { appState.config.capsLockReservedKey },
                        set: { appState.setReservedKey($0) }
                    )) {
                        Text(CapsLockReservedKey.f19.title).tag(CapsLockReservedKey.f19)
                        Text(CapsLockReservedKey.f20.title).tag(CapsLockReservedKey.f20)
                    }
                    .pickerStyle(.segmented)

                    Text("F18 は引き続き使えます。キーボード本体や他のアプリの割り当ては検出できない場合があります。使っていない方のファンクションキーを選んでください。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("キーボードを再読み込み", action: appState.refreshSetup)
                }
                .padding(.top, 8)
            }

            if let issue = appState.capsLockSetupIssue {
                Label(issue, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Button("接続と設定を再確認", action: appState.refreshSetup)
            }

            if !appState.capsLockConflicts.isEmpty {
                ModifierConflictWarningCard(
                    conflicts: appState.capsLockConflicts,
                    onOpenKeyboardSettings: appState.openKeyboardModifierSettings,
                    onRecheck: appState.refreshSetup
                )
            }
        }
    }
}
