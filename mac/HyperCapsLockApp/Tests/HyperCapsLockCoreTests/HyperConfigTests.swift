import Foundation
import Testing
@testable import HyperCapsLockCore

@Suite("HyperConfig Tests")
struct HyperConfigTests {
    @Test("デフォルトで相棒ボイスは有効になっている")
    func defaultCompanionSoundIsEnabled() {
        let config = HyperConfig()
        #expect(config.companionSoundEnabled == true)
    }

    @Test("companionSoundEnabledを含まない旧JSONをデコードしてもデフォルトONで復元される")
    func decodesLegacyJsonWithoutCompanionSoundKey() throws {
        let legacyJSON = """
        {
          "isEnabled": true,
          "onboardingStep": "completed",
          "starterEnabled": true,
          "windowSplitEnabled": false,
          "navigationEnabled": false,
          "jisEisuuEnabled": false,
          "passthroughUnassignedAsFourModifiers": false,
          "tapThresholdMs": 200,
          "launchAtLogin": false
        }
        """

        let decoded = try JSONDecoder().decode(HyperConfig.self, from: Data(legacyJSON.utf8))
        #expect(!decoded.isEnabled)
        #expect(decoded.onboardingStep == .completed)
        #expect(decoded.starterEnabled)
        #expect(decoded.companionSoundEnabled == true)
    }

    @Test("相棒ボイスをOFFにして保存・復元できる")
    func roundTripsDisabledCompanionSound() throws {
        var config = HyperConfig()
        config.companionSoundEnabled = false
        config.triggerMode = .eisuu

        let encoded = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(HyperConfig.self, from: encoded)
        #expect(!decoded.companionSoundEnabled)
        #expect(decoded.triggerMode == .eisuu)
    }
}
