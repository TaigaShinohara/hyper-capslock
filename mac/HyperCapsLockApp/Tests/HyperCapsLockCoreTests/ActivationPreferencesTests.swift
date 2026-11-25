import Foundation
import Testing
@testable import HyperCapsLockCore

@Suite("Activation preferences")
struct ActivationPreferencesTests {
    @Test("初回は停止中で、追加ショートカットと外部転送はオフ")
    func freshInstallIsInactive() {
        let config = HyperConfig()
        #expect(!config.isEnabled)
        #expect(config.onboardingStep == .permissions)
        #expect(!config.starterEnabled)
        #expect(!config.chatShortcutEnabled)
        #expect(!config.panelShortcutEnabled)
        #expect(!config.passthroughUnassignedAsFourModifiers)
    }

    @Test("旧版のオン状態を引き継がず、完了状態と個別の設定を保つ")
    func legacyPreferencesArePreservedWithoutActivation() throws {
        let saved = """
        {"isEnabled":true,"onboardingStep":"completed","starterEnabled":true,"jisEisuuEnabled":true,
         "passthroughUnassignedAsFourModifiers":true,"tapThresholdMs":240}
        """
        let config = try JSONDecoder().decode(HyperConfig.self, from: Data(saved.utf8))
        #expect(!config.isEnabled)
        #expect(config.onboardingStep == .completed)
        #expect(config.triggerMode == .capsLockAndEisuu)
        #expect(config.starterEnabled && config.chatShortcutEnabled && config.panelShortcutEnabled)
        #expect(config.passthroughUnassignedAsFourModifiers)
        #expect(config.tapThresholdMs == 240)
    }

    @Test("途中の試用は次の起動で再開せず、選択したキーや個別設定は保つ")
    func interruptedTrialIsNotResumed() throws {
        let saved = HyperConfig(
            isEnabled: true, onboardingStep: .testEsc, triggerMode: .eisuu,
            capsLockReservedKey: .f19, chatShortcutEnabled: false, panelShortcutEnabled: true
        )
        let data = try JSONEncoder().encode(saved)
        let config = try JSONDecoder().decode(HyperConfig.self, from: data)
        #expect(!config.isEnabled)
        #expect(config.onboardingStep == .permissions)
        #expect(config.triggerMode == .eisuu)
        #expect(config.capsLockReservedKey == .f19)
        #expect(!config.chatShortcutEnabled && config.panelShortcutEnabled)
    }

    @Test("旧版で途中だった数字キーの試用を設定として残さない")
    func legacyUnfinishedStarterWasOnlyATest() throws {
        let data = Data(#"{"isEnabled":true,"onboardingStep":"starter","starterEnabled":true}"#.utf8)
        let config = try JSONDecoder().decode(HyperConfig.self, from: data)
        #expect(!config.isEnabled)
        #expect(!config.starterEnabled && !config.chatShortcutEnabled && !config.panelShortcutEnabled)
    }
}
