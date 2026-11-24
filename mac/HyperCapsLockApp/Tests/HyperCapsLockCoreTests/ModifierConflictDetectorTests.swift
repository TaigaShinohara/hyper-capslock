import Testing
@testable import HyperCapsLockCore

@Suite("ModifierConflictDetector Tests")
struct ModifierConflictDetectorTests {
    @Test("CapsLockが別の修飾キーへ割り当てられている場合に競合を検出する")
    func detectsCapsLockRemappedToCommandOrControl() {
        let devices = [
            KeyboardModifierDeviceSnapshot(
                deviceName: "Apple Internal Keyboard / Trackpad",
                mappings: [
                    HidKeyMappingEntry(src: 0x700000039, dst: 0x7000000E7), // CapsLock -> Right Command
                    HidKeyMappingEntry(src: 0x7000000E3, dst: 0x7000000E0), // Left Command -> Left Control
                ]
            ),
            KeyboardModifierDeviceSnapshot(
                deviceName: "External Keychron",
                mappings: [
                    HidKeyMappingEntry(src: 0x700000039, dst: 0x7000000E0), // CapsLock -> Left Control
                ]
            ),
        ]

        let conflicts = ModifierConflictDetector.detectConflicts(in: devices)
        #expect(conflicts.count == 2)
        #expect(conflicts[0].deviceName == "内蔵キーボード")
        #expect(conflicts[0].mappedDestinationName == "⌘ Command")
        #expect(conflicts[1].deviceName == "External Keychron")
        #expect(conflicts[1].mappedDestinationName == "⌃ Control")
    }

    @Test("CommandとControlの入れ替えだけでは競合として検出しない")
    func ignoresOtherModifierSwapsWithoutCapsLock() {
        let devices = [
            KeyboardModifierDeviceSnapshot(
                deviceName: "Apple Internal Keyboard / Trackpad",
                mappings: [
                    HidKeyMappingEntry(src: 0x7000000E3, dst: 0x7000000E0),
                    HidKeyMappingEntry(src: 0x7000000E7, dst: 0x7000000E4),
                    HidKeyMappingEntry(src: 0x700000039, dst: 0x700000039),
                ]
            ),
        ]

        let conflicts = ModifierConflictDetector.detectConflicts(in: devices)
        #expect(conflicts.isEmpty)
    }

    @Test("仮想キーコードから修飾キー表示名を取得できる")
    func mapsVirtualKeyCodesToReadableNames() {
        #expect(ModifierConflictDetector.modifierKeyDisplayName(forVirtualKeyCode: 54) == "右 ⌘ Command")
        #expect(ModifierConflictDetector.modifierKeyDisplayName(forVirtualKeyCode: 62) == "右 ⌃ Control")
        #expect(ModifierConflictDetector.modifierKeyDisplayName(forVirtualKeyCode: 999) == nil)
    }
}
