import Foundation

/// HyperEngine が処理するキーイベント種別。
public enum KeyEventKind: Sendable, Equatable {
    case keyDown
    case keyUp
}

/// HyperEngine への入力イベント。
public struct HyperKeyInput: Sendable, Equatable {
    public let keyCode: Int
    public let kind: KeyEventKind
    public let isAutorepeat: Bool
    public let timestampMs: Int64
    public let frontmostBundleIdentifier: String?
    /// ユーザーがトリガー以外に物理的に押している修飾キーのビットマスク（Command/Shift/Control/Option）。
    public let modifierBits: UInt64

    public init(
        keyCode: Int,
        kind: KeyEventKind,
        isAutorepeat: Bool = false,
        timestampMs: Int64,
        frontmostBundleIdentifier: String? = nil,
        modifierBits: UInt64 = 0
    ) {
        self.keyCode = keyCode
        self.kind = kind
        self.isAutorepeat = isAutorepeat
        self.timestampMs = timestampMs
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.modifierBits = modifierBits
    }
}

/// 合成キーイベントに付ける修飾フラグ。
public struct HyperModifierFlags: OptionSet, Sendable, Equatable, Hashable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let command = HyperModifierFlags(rawValue: 1 << 0)
    public static let control = HyperModifierFlags(rawValue: 1 << 1)
    public static let option = HyperModifierFlags(rawValue: 1 << 2)
    public static let shift = HyperModifierFlags(rawValue: 1 << 3)

    public static let hyperFour: HyperModifierFlags = [.command, .control, .option, .shift]
}

/// ウィンドウ配置方向。
public enum WindowSnapSide: String, Sendable, Equatable {
    case leftHalf
    case rightHalf
}

/// HyperEngine が生成する出力アクション。
public enum HyperAction: Sendable, Equatable {
    case sendKey(keyCode: Int, kind: KeyEventKind, modifiers: HyperModifierFlags)
    case activateApp(AppTarget)
    case snapWindow(WindowSnapSide)
    case blocked(reason: String, inputKeyCode: Int)
}

/// UI のライブ動作モニター向けログイベント。
public struct HyperFeedbackEvent: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let summary: String
    public let detail: String
    public let isSuccess: Bool
    public let isEscTap: Bool

    public init(
        id: UUID = UUID(),
        summary: String,
        detail: String,
        isSuccess: Bool = true,
        isEscTap: Bool = false
    ) {
        self.id = id
        self.summary = summary
        self.detail = detail
        self.isSuccess = isSuccess
        self.isEscTap = isEscTap
    }
}

/// 1 回のキー入力に対するエンジン判定結果。
public struct HyperDecision: Sendable, Equatable {
    public let shouldConsume: Bool
    public let actions: [HyperAction]
    public let isHoldingHyper: Bool
    public let feedback: HyperFeedbackEvent?

    public init(
        shouldConsume: Bool,
        actions: [HyperAction] = [],
        isHoldingHyper: Bool,
        feedback: HyperFeedbackEvent? = nil
    ) {
        self.shouldConsume = shouldConsume
        self.actions = actions
        self.isHoldingHyper = isHoldingHyper
        self.feedback = feedback
    }
}

/// CapsLock 単押し Esc / 長押し Hyper を判定する純粋ステートマシン。
public final class HyperEngine: @unchecked Sendable {
    private enum InterceptedKeyMode: Equatable {
        case mappedKey(outputKeyCode: Int, modifiers: HyperModifierFlags)
        case consumedOnly
    }

    private var activeTriggerKeyCode: Int?
    private var triggerDownTimestampMs: Int64 = 0
    private var hasPressedOtherKey: Bool = false
    private var activeInterceptedKeys: [Int: InterceptedKeyMode] = [:]

    public var isHolding: Bool {
        activeTriggerKeyCode != nil
    }

    public init() {}

    public func reset() -> [HyperAction] {
        let releaseActions = flushPressedMappedKeys()
        activeTriggerKeyCode = nil
        triggerDownTimestampMs = 0
        hasPressedOtherKey = false
        return releaseActions
    }

    public func handle(_ input: HyperKeyInput, config: HyperConfig) -> HyperDecision {
        guard config.isEnabled else {
            return HyperDecision(shouldConsume: false, actions: [], isHoldingHyper: false)
        }

        if isTriggerKey(input.keyCode, config: config) {
            return handleTriggerEvent(input, config: config)
        }

        // トリガー押下中に変換開始したキーの keyUp は、トリガー状態に関わらず対で解放・消費する
        if input.kind == .keyUp, let mode = activeInterceptedKeys.removeValue(forKey: input.keyCode) {
            switch mode {
            case let .mappedKey(outputKeyCode, modifiers):
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.sendKey(keyCode: outputKeyCode, kind: .keyUp, modifiers: modifiers)],
                    isHoldingHyper: isHolding
                )
            case .consumedOnly:
                return HyperDecision(shouldConsume: true, actions: [], isHoldingHyper: isHolding)
            }
        }

        guard isHolding else {
            return HyperDecision(shouldConsume: false, actions: [], isHoldingHyper: false)
        }

        if input.keyCode == KeyCodeCatalog.f18 || input.keyCode == KeyCodeCatalog.f19 || input.keyCode == KeyCodeCatalog.f20 {
            if input.kind == .keyDown { hasPressedOtherKey = true }
            return HyperDecision(shouldConsume: false, isHoldingHyper: true)
        }

        return handleKeyWhileHolding(input, config: config)
    }

    // MARK: - Private

    private func isTriggerKey(_ keyCode: Int, config: HyperConfig) -> Bool {
        (config.triggerMode.usesCapsLock && keyCode == config.capsLockReservedKey.keyCode)
            || (config.triggerMode.usesEisuu && keyCode == KeyCodeCatalog.jisEisuu)
    }

    private func handleTriggerEvent(_ input: HyperKeyInput, config: HyperConfig) -> HyperDecision {
        switch input.kind {
        case .keyDown:
            if input.isAutorepeat {
                return HyperDecision(shouldConsume: true, actions: [], isHoldingHyper: true)
            }
            if activeTriggerKeyCode == nil {
                activeTriggerKeyCode = input.keyCode
                triggerDownTimestampMs = input.timestampMs
                hasPressedOtherKey = false
            }
            return HyperDecision(shouldConsume: true, actions: [], isHoldingHyper: true)

        case .keyUp:
            guard activeTriggerKeyCode == input.keyCode else {
                // 別のトリガーキーがアクティブ、または非アクティブ状態での keyUp
                return HyperDecision(shouldConsume: isHolding, actions: [], isHoldingHyper: isHolding)
            }

            let elapsed = input.timestampMs - triggerDownTimestampMs
            let shouldSendEsc = !hasPressedOtherKey && elapsed <= Int64(config.tapThresholdMs)

            var actions = flushPressedMappedKeys()
            activeTriggerKeyCode = nil
            triggerDownTimestampMs = 0
            hasPressedOtherKey = false

            var feedback: HyperFeedbackEvent?
            if shouldSendEsc {
                actions.append(.sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyDown, modifiers: []))
                actions.append(.sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyUp, modifiers: []))
                feedback = HyperFeedbackEvent(
                    summary: "単押し → Esc",
                    detail: "Esc を送信（\(max(0, elapsed))ms）",
                    isSuccess: true,
                    isEscTap: true
                )
            }

            return HyperDecision(
                shouldConsume: true,
                actions: actions,
                isHoldingHyper: false,
                feedback: feedback
            )
        }
    }

    private func handleKeyWhileHolding(_ input: HyperKeyInput, config: HyperConfig) -> HyperDecision {
        guard input.kind == .keyDown else {
            return HyperDecision(shouldConsume: true, actions: [], isHoldingHyper: true)
        }

        hasPressedOtherKey = true

        // 1. 安全ルール: Hyper + ピリオドは常時ブロック（sysdiagnose 誤爆防止）
        if input.keyCode == KeyCodeCatalog.period {
            activeInterceptedKeys[input.keyCode] = .consumedOnly
            if input.isAutorepeat {
                return HyperDecision(shouldConsume: true, isHoldingHyper: true)
            }
            return HyperDecision(
                shouldConsume: true,
                actions: [.blocked(reason: "診断ショートカット誤爆を防止", inputKeyCode: input.keyCode)],
                isHoldingHyper: true,
                feedback: HyperFeedbackEvent(
                    summary: "安全ブロック: Hyper + .",
                    detail: "macOS 診断収集の誤発動を防止しました",
                    isSuccess: true
                )
            )
        }

        // 2. 往復スターター
        if let decision = handleStarterKey(input, config: config) {
            return decision
        }

        // 3. ウィンドウ左右分割
        if config.windowSplitEnabled {
            if input.keyCode == KeyCodeCatalog.q || input.keyCode == KeyCodeCatalog.w {
                activeInterceptedKeys[input.keyCode] = .consumedOnly
                if input.isAutorepeat {
                    return HyperDecision(shouldConsume: true, isHoldingHyper: true)
                }
                let side: WindowSnapSide = (input.keyCode == KeyCodeCatalog.q) ? .leftHalf : .rightHalf
                let label = (side == .leftHalf) ? "ウィンドウを左半分へ" : "ウィンドウを右半分へ"
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.snapWindow(side)],
                    isHoldingHyper: true,
                    feedback: HyperFeedbackEvent(
                        summary: "Hyper+\(KeyCodeCatalog.displayName(for: input.keyCode)) → \(label)",
                        detail: "ウィンドウ配置",
                        isSuccess: true
                    )
                )
            }
        }

        // 4. 第2弾（カーソル・単語移動）
        if config.navigationEnabled {
            if let decision = handleNavigationKey(input) {
                return decision
            }
        }

        // 5. 未割り当てキー
        if config.passthroughUnassignedAsFourModifiers {
            let mode = InterceptedKeyMode.mappedKey(outputKeyCode: input.keyCode, modifiers: .hyperFour)
            activeInterceptedKeys[input.keyCode] = mode
            return HyperDecision(
                shouldConsume: true,
                actions: [.sendKey(keyCode: input.keyCode, kind: .keyDown, modifiers: .hyperFour)],
                isHoldingHyper: true,
                feedback: input.isAutorepeat ? nil : HyperFeedbackEvent(
                    summary: "Hyper+\(KeyCodeCatalog.displayName(for: input.keyCode))（4修飾パススルー）",
                    detail: "Cmd+Ctrl+Opt+Shift と一緒に送信",
                    isSuccess: true
                )
            )
        }

        // 既定: 安全のため未割り当てキーは無効化（誤爆防止）
        activeInterceptedKeys[input.keyCode] = .consumedOnly
        if input.isAutorepeat {
            return HyperDecision(shouldConsume: true, isHoldingHyper: true)
        }
        return HyperDecision(
            shouldConsume: true,
            actions: [.blocked(reason: "未割り当てキーを安全ガード", inputKeyCode: input.keyCode)],
            isHoldingHyper: true,
            feedback: HyperFeedbackEvent(
                summary: "Hyper+\(KeyCodeCatalog.displayName(for: input.keyCode))（無効化）",
                detail: "未割り当てのため誤爆防止でブロック",
                isSuccess: true
            )
        )
    }

    private func handleStarterKey(_ input: HyperKeyInput, config: HyperConfig) -> HyperDecision? {
        switch input.keyCode {
        case KeyCodeCatalog.c where config.chatShortcutEnabled:
            let frontID = input.frontmostBundleIdentifier
            if frontID == KeyCodeCatalog.cursorBundleID {
                let mode = InterceptedKeyMode.mappedKey(outputKeyCode: KeyCodeCatalog.l, modifiers: .command)
                activeInterceptedKeys[input.keyCode] = mode
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.sendKey(keyCode: KeyCodeCatalog.l, kind: .keyDown, modifiers: .command)],
                    isHoldingHyper: true,
                    feedback: input.isAutorepeat ? nil : HyperFeedbackEvent(
                        summary: "Hyper+C → Cursor に ⌘L を送信",
                        detail: "Command+L を送信",
                        isSuccess: true
                    )
                )
            } else {
                activeInterceptedKeys[input.keyCode] = .consumedOnly
                if input.isAutorepeat {
                    return HyperDecision(shouldConsume: true, isHoldingHyper: true)
                }
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.activateApp(config.slot1App)],
                    isHoldingHyper: true,
                    feedback: HyperFeedbackEvent(
                        summary: "Hyper+C → \(config.slot1App.name) に切り替えを要求",
                        detail: "Cursor が前面にない場合の動作",
                        isSuccess: true
                    )
                )
            }

        case KeyCodeCatalog.t where config.panelShortcutEnabled:
            let frontID = input.frontmostBundleIdentifier
            if frontID == KeyCodeCatalog.cursorBundleID || frontID == KeyCodeCatalog.vsCodeBundleID {
                let mode = InterceptedKeyMode.mappedKey(outputKeyCode: KeyCodeCatalog.j, modifiers: .command)
                activeInterceptedKeys[input.keyCode] = mode
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.sendKey(keyCode: KeyCodeCatalog.j, kind: .keyDown, modifiers: .command)],
                    isHoldingHyper: true,
                    feedback: input.isAutorepeat ? nil : HyperFeedbackEvent(
                        summary: "Hyper+T → ⌘J を送信",
                        detail: "Command+J を送信",
                        isSuccess: true
                    )
                )
            } else {
                activeInterceptedKeys[input.keyCode] = .consumedOnly
                if input.isAutorepeat {
                    return HyperDecision(shouldConsume: true, isHoldingHyper: true)
                }
                return HyperDecision(
                    shouldConsume: true,
                    actions: [.blocked(reason: "エディタ以外のため Hyper+T を無視", inputKeyCode: input.keyCode)],
                    isHoldingHyper: true,
                    feedback: HyperFeedbackEvent(
                        summary: "Hyper+T（Cursor / VS Code 以外では無効）",
                        detail: "他アプリへの誤送信を防止",
                        isSuccess: true
                    )
                )
            }

        case KeyCodeCatalog.num1, KeyCodeCatalog.num2, KeyCodeCatalog.num3:
            guard config.starterEnabled else { return nil }
            if config.onboardingStep == .starter && input.keyCode != KeyCodeCatalog.num1 { return nil }
            activeInterceptedKeys[input.keyCode] = .consumedOnly
            if input.isAutorepeat {
                return HyperDecision(shouldConsume: true, isHoldingHyper: true)
            }
            let slot: Int
            switch input.keyCode {
            case KeyCodeCatalog.num1: slot = 1
            case KeyCodeCatalog.num2: slot = 2
            default: slot = 3
            }
            let target = config.appTarget(forSlot: slot)
            return HyperDecision(
                shouldConsume: true,
                actions: [.activateApp(target)],
                isHoldingHyper: true,
                feedback: HyperFeedbackEvent(
                    summary: "Hyper+\(slot) → \(target.name) に切り替えを要求",
                    detail: "アプリを前面へ切り替え",
                    isSuccess: true
                )
            )

        default:
            return nil
        }
    }

    private func handleNavigationKey(_ input: HyperKeyInput) -> HyperDecision? {
        let mapping: (outputCode: Int, modifiers: HyperModifierFlags, label: String)?
        switch input.keyCode {
        case KeyCodeCatalog.h:
            mapping = (KeyCodeCatalog.leftArrow, [], "←")
        case KeyCodeCatalog.j:
            mapping = (KeyCodeCatalog.downArrow, [], "↓")
        case KeyCodeCatalog.k:
            mapping = (KeyCodeCatalog.upArrow, [], "↑")
        case KeyCodeCatalog.l:
            mapping = (KeyCodeCatalog.rightArrow, [], "→")
        case KeyCodeCatalog.a:
            mapping = (KeyCodeCatalog.leftArrow, .command, "行頭")
        case KeyCodeCatalog.e:
            mapping = (KeyCodeCatalog.rightArrow, .command, "行末")
        case KeyCodeCatalog.b:
            mapping = (KeyCodeCatalog.leftArrow, .option, "前の単語")
        case KeyCodeCatalog.f:
            mapping = (KeyCodeCatalog.rightArrow, .option, "次の単語")
        default:
            mapping = nil
        }

        guard let mapped = mapping else {
            return nil
        }

        activeInterceptedKeys[input.keyCode] = .mappedKey(
            outputKeyCode: mapped.outputCode,
            modifiers: mapped.modifiers
        )
        return HyperDecision(
            shouldConsume: true,
            actions: [.sendKey(keyCode: mapped.outputCode, kind: .keyDown, modifiers: mapped.modifiers)],
            isHoldingHyper: true,
            feedback: input.isAutorepeat ? nil : HyperFeedbackEvent(
                summary: "Hyper+\(KeyCodeCatalog.displayName(for: input.keyCode)) → \(mapped.label)",
                detail: "移動キー",
                isSuccess: true
            )
        )
    }

    private func flushPressedMappedKeys() -> [HyperAction] {
        var actions: [HyperAction] = []
        for (_, mode) in activeInterceptedKeys {
            if case let .mappedKey(outputKeyCode, modifiers) = mode {
                actions.append(.sendKey(keyCode: outputKeyCode, kind: .keyUp, modifiers: modifiers))
            }
        }
        activeInterceptedKeys.removeAll()
        return actions
    }
}
