import Testing
@testable import HyperCapsLockCore

@Suite("HyperEngine Tests")
struct HyperEngineTests {
    private func makeDefaultConfig(
        starter: Bool = true,
        windowSplit: Bool = false,
        navigation: Bool = false,
        jisEisuu: Bool = false,
        passthrough: Bool = false
    ) -> HyperConfig {
        HyperConfig(
            isEnabled: true,
            onboardingStep: .completed,
            starterEnabled: starter,
            windowSplitEnabled: windowSplit,
            navigationEnabled: navigation,
            triggerMode: jisEisuu ? .capsLockAndEisuu : .capsLock,
            chatShortcutEnabled: starter,
            panelShortcutEnabled: starter,
            passthroughUnassignedAsFourModifiers: passthrough,
            tapThresholdMs: 200
        )
    }

    @Test("CapsLock単押し（200ms以下）でEscが出る")
    func tapWithinThresholdProducesEscape() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        let down = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        #expect(down.shouldConsume == true)
        #expect(down.isHoldingHyper == true)
        #expect(down.actions.isEmpty)

        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyUp, timestampMs: 1200),
            config: config
        )
        #expect(up.shouldConsume == true)
        #expect(up.isHoldingHyper == false)
        #expect(up.actions == [
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyDown, modifiers: []),
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyUp, modifiers: []),
        ])
        #expect(up.feedback?.isEscTap == true)
    }

    @Test("200ms超の長押し後に何も押さず離してもEscは出ない")
    func longHoldWithoutOtherKeyProducesNothing() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyUp, timestampMs: 1201),
            config: config
        )

        #expect(up.shouldConsume == true)
        #expect(up.isHoldingHyper == false)
        #expect(up.actions.isEmpty)
        #expect(up.feedback == nil)
    }

    @Test("Escの閾値ちょうど200msでは単押しを認識する")
    func exactTapThresholdProducesEscape() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyUp, timestampMs: 1200),
            config: config
        )

        #expect(up.actions == [
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyDown, modifiers: []),
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyUp, modifiers: []),
        ])
    }

    @Test("200ms以内に別キーを同時押しした場合、離してもEscは出ない")
    func rolloverWithin200MsSuppressesEscape() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        let spaceDown = engine.handle(
            HyperKeyInput(keyCode: 49, kind: .keyDown, timestampMs: 1050),
            config: config
        )
        #expect(spaceDown.shouldConsume == true)

        _ = engine.handle(
            HyperKeyInput(keyCode: 49, kind: .keyUp, timestampMs: 1080),
            config: config
        )

        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyUp, timestampMs: 1120),
            config: config
        )
        #expect(up.actions.isEmpty)
    }

    @Test("安全モード：未割り当てキー（Q/Wオフ時やピリオド）は4修飾を送らず破棄される")
    func unassignedAndPeriodAreSafelyBlocked() {
        let engine = HyperEngine()
        let config = makeDefaultConfig(windowSplit: false, passthrough: false)

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )

        let qDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.q, kind: .keyDown, timestampMs: 1050),
            config: config
        )
        #expect(qDown.shouldConsume == true)
        #expect(qDown.actions == [.blocked(reason: "未割り当てキーを安全ガード", inputKeyCode: KeyCodeCatalog.q)])

        let dotDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.period, kind: .keyDown, timestampMs: 1100),
            config: config
        )
        #expect(dotDown.shouldConsume == true)
        #expect(dotDown.actions == [.blocked(reason: "診断ショートカット誤爆を防止", inputKeyCode: KeyCodeCatalog.period)])
    }

    @Test("パススルーON時：未割り当てキーは4修飾が付くがピリオドは引き続きブロック")
    func passthroughForwardsFourModifiersExceptPeriod() {
        let engine = HyperEngine()
        let config = makeDefaultConfig(windowSplit: false, passthrough: true)

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )

        let qDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.q, kind: .keyDown, timestampMs: 1050),
            config: config
        )
        #expect(qDown.actions == [.sendKey(keyCode: KeyCodeCatalog.q, kind: .keyDown, modifiers: .hyperFour)])

        let qUp = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.q, kind: .keyUp, timestampMs: 1100),
            config: config
        )
        #expect(qUp.actions == [.sendKey(keyCode: KeyCodeCatalog.q, kind: .keyUp, modifiers: .hyperFour)])

        let dotDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.period, kind: .keyDown, timestampMs: 1150),
            config: config
        )
        #expect(dotDown.actions == [.blocked(reason: "診断ショートカット誤爆を防止", inputKeyCode: KeyCodeCatalog.period)])
    }

    @Test("Hyper+CとHyper+Tは前面アプリに応じて分岐する")
    func starterChatAndPanelRespectFrontmostApp() {
        let engine = HyperEngine()
        let config = makeDefaultConfig(starter: true)

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )

        // Cursor前面でのHyper+C -> Command+L
        let cInCursor = engine.handle(
            HyperKeyInput(
                keyCode: KeyCodeCatalog.c,
                kind: .keyDown,
                timestampMs: 1050,
                frontmostBundleIdentifier: KeyCodeCatalog.cursorBundleID
            ),
            config: config
        )
        #expect(cInCursor.actions == [.sendKey(keyCode: KeyCodeCatalog.l, kind: .keyDown, modifiers: .command)])

        // Chrome前面でのHyper+C -> slot1App前面化のみ
        let cInChrome = engine.handle(
            HyperKeyInput(
                keyCode: KeyCodeCatalog.c,
                kind: .keyDown,
                timestampMs: 1100,
                frontmostBundleIdentifier: "com.google.Chrome"
            ),
            config: config
        )
        #expect(cInChrome.actions == [.activateApp(config.slot1App)])

        // VS Code前面でのHyper+T -> Command+J
        let tInVSCode = engine.handle(
            HyperKeyInput(
                keyCode: KeyCodeCatalog.t,
                kind: .keyDown,
                timestampMs: 1150,
                frontmostBundleIdentifier: KeyCodeCatalog.vsCodeBundleID
            ),
            config: config
        )
        #expect(tInVSCode.actions == [.sendKey(keyCode: KeyCodeCatalog.j, kind: .keyDown, modifiers: .command)])

        // Chrome前面でのHyper+T -> ブロック
        let tInChrome = engine.handle(
            HyperKeyInput(
                keyCode: KeyCodeCatalog.t,
                kind: .keyDown,
                timestampMs: 1200,
                frontmostBundleIdentifier: "com.google.Chrome"
            ),
            config: config
        )
        #expect(tInChrome.actions == [.blocked(reason: "エディタ以外のため Hyper+T を無視", inputKeyCode: KeyCodeCatalog.t)])
    }

    @Test("ウィンドウ左右分割と第2弾移動キー（先にCapsLockを離してもkeyUpが解放される）")
    func windowSplitAndNavigationFlush() {
        let engine = HyperEngine()
        let config = makeDefaultConfig(starter: true, windowSplit: true, navigation: true)

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000),
            config: config
        )

        let qDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.q, kind: .keyDown, timestampMs: 1050),
            config: config
        )
        #expect(qDown.actions == [.snapWindow(.leftHalf)])

        let aDown = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.a, kind: .keyDown, timestampMs: 1100),
            config: config
        )
        #expect(aDown.actions == [.sendKey(keyCode: KeyCodeCatalog.leftArrow, kind: .keyDown, modifiers: .command)])

        // Aを離す前にCapsLockを離しても、Command+LeftArrowのkeyUpが安全に送られる
        let capsUp = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyUp, timestampMs: 1300),
            config: config
        )
        #expect(capsUp.actions == [.sendKey(keyCode: KeyCodeCatalog.leftArrow, kind: .keyUp, modifiers: .command)])
    }

    @Test("JIS英数キーはオプションONのときだけHyperになる")
    func jisEisuuFollowsConfigFlag() {
        let engine = HyperEngine()

        let offConfig = makeDefaultConfig(jisEisuu: false)
        let ignored = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.jisEisuu, kind: .keyDown, timestampMs: 1000),
            config: offConfig
        )
        #expect(ignored.shouldConsume == false)

        let onConfig = makeDefaultConfig(jisEisuu: true)
        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.jisEisuu, kind: .keyDown, timestampMs: 2000),
            config: onConfig
        )
        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.jisEisuu, kind: .keyUp, timestampMs: 2080),
            config: onConfig
        )
        #expect(up.actions == [
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyDown, modifiers: []),
            .sendKey(keyCode: KeyCodeCatalog.escape, kind: .keyUp, modifiers: []),
        ])
    }

    @Test("F18 と選択していない予約キーは通過し、英数専用モードは F19 / F20 に触れない")
    func onlySelectedTriggersAreConsumed() {
        let engine = HyperEngine()
        var config = makeDefaultConfig()
        config.capsLockReservedKey = .f19

        func down(_ keyCode: Int) -> HyperDecision {
            engine.handle(HyperKeyInput(keyCode: keyCode, kind: .keyDown, timestampMs: 1000), config: config)
        }

        #expect(!down(KeyCodeCatalog.f18).shouldConsume)
        #expect(!down(KeyCodeCatalog.f20).shouldConsume)
        #expect(down(KeyCodeCatalog.f19).shouldConsume)
        _ = engine.reset()

        config.triggerMode = .eisuu
        #expect(!down(KeyCodeCatalog.f18).shouldConsume)
        #expect(!down(KeyCodeCatalog.f19).shouldConsume)
        #expect(!down(KeyCodeCatalog.f20).shouldConsume)
        #expect(down(KeyCodeCatalog.jisEisuu).shouldConsume)
    }

    @Test("C / T を個別にオフにすると未割り当てとして外部に転送できる")
    func disabledEditorShortcutsUseUnassignedPolicy() {
        let engine = HyperEngine()
        var config = makeDefaultConfig(passthrough: true)
        config.chatShortcutEnabled = false
        config.panelShortcutEnabled = false
        _ = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000), config: config)
        for keyCode in [KeyCodeCatalog.c, KeyCodeCatalog.t] {
            let decision = engine.handle(
                HyperKeyInput(keyCode: keyCode, kind: .keyDown, timestampMs: 1010, frontmostBundleIdentifier: KeyCodeCatalog.cursorBundleID),
                config: config
            )
            #expect(decision.actions == [.sendKey(keyCode: keyCode, kind: .keyDown, modifiers: .hyperFour)])
        }
    }

    @Test("Hyper を保持していても F18 と使っていない予約キーを変換しない")
    func otherFunctionKeysKeepTheirAssignmentsDuringHyper() {
        let engine = HyperEngine()
        var config = makeDefaultConfig(passthrough: true)
        config.capsLockReservedKey = .f19
        _ = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.f19, kind: .keyDown, timestampMs: 1000), config: config)

        for keyCode in [KeyCodeCatalog.f18, KeyCodeCatalog.f20] {
            let decision = engine.handle(
                HyperKeyInput(keyCode: keyCode, kind: .keyDown, timestampMs: 1010), config: config
            )
            #expect(!decision.shouldConsume && decision.actions.isEmpty)
        }

        let release = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.f19, kind: .keyUp, timestampMs: 1040), config: config)
        #expect(release.actions.isEmpty)
    }

    @Test("数字ショートカットを使わなくてもエディタ操作を個別に有効にできる")
    func editorShortcutsDoNotDependOnNumericShortcuts() {
        let engine = HyperEngine()
        var config = makeDefaultConfig(starter: false)
        config.chatShortcutEnabled = true
        _ = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000), config: config)
        let chat = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.c, kind: .keyDown, timestampMs: 1010, frontmostBundleIdentifier: KeyCodeCatalog.cursorBundleID),
            config: config
        )
        #expect(chat.actions == [.sendKey(keyCode: KeyCodeCatalog.l, kind: .keyDown, modifiers: .command)])
        let number = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.num1, kind: .keyDown, timestampMs: 1020), config: config)
        #expect(number.actions == [.blocked(reason: "未割り当てキーを安全ガード", inputKeyCode: KeyCodeCatalog.num1)])
    }

    @Test("初回の数字キー試用は 1 だけを有効にする")
    func onlySlotOneActivatesDuringTrial() {
        let engine = HyperEngine()
        var config = makeDefaultConfig()
        config.onboardingStep = .starter
        _ = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.f20, kind: .keyDown, timestampMs: 1000), config: config)

        let first = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.num1, kind: .keyDown, timestampMs: 1010), config: config)
        let second = engine.handle(HyperKeyInput(keyCode: KeyCodeCatalog.num2, kind: .keyDown, timestampMs: 1020), config: config)
        #expect(first.actions == [.activateApp(config.slot1App)])
        #expect(second.actions == [.blocked(reason: "未割り当てキーを安全ガード", inputKeyCode: KeyCodeCatalog.num2)])
    }
}
