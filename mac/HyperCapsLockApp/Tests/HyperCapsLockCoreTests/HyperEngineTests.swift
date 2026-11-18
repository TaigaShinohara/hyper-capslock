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
            jisEisuuEnabled: jisEisuu,
            passthroughUnassignedAsFourModifiers: passthrough,
            tapThresholdMs: 200
        )
    }

    @Test("CapsLock単押し（200ms以下）でEscが出る")
    func tapWithinThresholdProducesEscape() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        let down = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        #expect(down.shouldConsume == true)
        #expect(down.isHoldingHyper == true)
        #expect(down.actions.isEmpty)

        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyUp, timestampMs: 1200),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
            config: config
        )
        let up = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyUp, timestampMs: 1201),
            config: config
        )

        #expect(up.shouldConsume == true)
        #expect(up.isHoldingHyper == false)
        #expect(up.actions.isEmpty)
        #expect(up.feedback == nil)
    }

    @Test("200ms以内に別キーを同時押しした場合、離してもEscは出ない")
    func rolloverWithin200MsSuppressesEscape() {
        let engine = HyperEngine()
        let config = makeDefaultConfig()

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyUp, timestampMs: 1120),
            config: config
        )
        #expect(up.actions.isEmpty)
    }

    @Test("安全モード：未割り当てキー（Q/Wオフ時やピリオド）は4修飾を送らず破棄される")
    func unassignedAndPeriodAreSafelyBlocked() {
        let engine = HyperEngine()
        let config = makeDefaultConfig(windowSplit: false, passthrough: false)

        _ = engine.handle(
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyDown, timestampMs: 1000),
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
            HyperKeyInput(keyCode: KeyCodeCatalog.f18, kind: .keyUp, timestampMs: 1300),
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
}
