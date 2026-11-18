import Testing
@testable import HyperCapsLockCore

@Suite("HidutilPlan Tests")
struct HidutilPlanTests {
    @Test("nullばかりのhidutil出力からは空配列を返す")
    func parsesNullOutputAsEmpty() {
        let output = """
        RegistryID  Key                   Value
        1000009ff   UserKeyMapping   (null)
        """
        #expect(HidutilPlan.parseMappings(fromHidutilOutput: output).isEmpty)
    }

    @Test("既存マッピングがある場合はパースして保持し、CapsLock->F18を安全に追加・削除できる")
    func preservesExistingMappingsWhenApplyingAndRemoving() throws {
        let output = """
        RegistryID  Key                   Value
        1000009ff   UserKeyMapping   (
            {
                HIDKeyboardModifierMappingDst = 30064771299;
                HIDKeyboardModifierMappingSrc = 30064771298;
            }
        )
        """
        let existing = HidutilPlan.parseMappings(fromHidutilOutput: output)
        #expect(existing == [HidKeyMappingEntry(src: 30064771298, dst: 30064771299)])

        let applied = HidutilPlan.applyingCapsLockToF18(on: existing)
        #expect(applied.count == 2)
        #expect(applied.contains(HidutilPlan.capsLockToF18Entry))

        let json = try HidutilPlan.encodeUserKeyMappingJSON(applied)
        #expect(json.contains("UserKeyMapping"))
        #expect(json.contains("30064771129")) // 0x700000039
        #expect(json.contains("30064771181")) // 0x70000006D

        let restored = HidutilPlan.removingManagedEntry(from: applied)
        #expect(restored == existing)
    }
}
