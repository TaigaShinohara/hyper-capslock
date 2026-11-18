import Foundation

/// 接続中キーボードの修飾キー設定スナップショット。
public struct KeyboardModifierDeviceSnapshot: Equatable, Sendable {
    public let deviceName: String
    public let mappings: [HidKeyMappingEntry]

    public init(deviceName: String, mappings: [HidKeyMappingEntry]) {
        self.deviceName = deviceName
        self.mappings = mappings
    }
}

/// macOS システム設定の「修飾キー」で CapsLock が別キーに変更されている競合情報。
public struct CapsLockSystemConflict: Equatable, Sendable, Identifiable {
    public var id: String { "\(deviceName)-\(destinationUsageID)" }
    public let deviceName: String
    public let destinationUsageID: UInt64
    public let mappedDestinationName: String

    public init(deviceName: String, destinationUsageID: UInt64, mappedDestinationName: String) {
        self.deviceName = deviceName
        self.destinationUsageID = destinationUsageID
        self.mappedDestinationName = mappedDestinationName
    }
}

/// システム設定の修飾キー割り当てから CapsLock 競合を検出する純粋ロジック。
public enum ModifierConflictDetector {
    public static func detectConflicts(in devices: [KeyboardModifierDeviceSnapshot]) -> [CapsLockSystemConflict] {
        var conflicts: [CapsLockSystemConflict] = []
        var seenIDs = Set<String>()

        for device in devices {
            for entry in device.mappings where entry.src == KeyCodeCatalog.hidCapsLock {
                guard entry.dst != KeyCodeCatalog.hidCapsLock else { continue }
                let destName = destinationDisplayName(for: entry.dst)
                let conflict = CapsLockSystemConflict(
                    deviceName: localizedDeviceName(device.deviceName),
                    destinationUsageID: entry.dst,
                    mappedDestinationName: destName
                )
                if !seenIDs.contains(conflict.id) {
                    seenIDs.insert(conflict.id)
                    conflicts.append(conflict)
                }
            }
        }

        return conflicts
    }

    public static func destinationDisplayName(for usageID: UInt64) -> String {
        switch usageID {
        case 0x7000000E0, 0x7000000E4:
            return "⌃ Control"
        case 0x7000000E1, 0x7000000E5:
            return "⇧ Shift"
        case 0x7000000E2, 0x7000000E6:
            return "⌥ Option"
        case 0x7000000E3, 0x7000000E7:
            return "⌘ Command"
        case 0x700000029:
            return "⎋ Escape"
        case 0x700000090, 0x700000091, 0x100000001, 0xFF00000003:
            return "🌐 地球儀 / Fn"
        case 0, 0xFFFFFFFF, 0x700000000:
            return "アクションなし（無効）"
        default:
            return "別のキー"
        }
    }

    public static func modifierKeyDisplayName(forVirtualKeyCode keyCode: Int) -> String? {
        switch keyCode {
        case 54: return "右 ⌘ Command"
        case 55: return "左 ⌘ Command"
        case 56: return "左 ⇧ Shift"
        case 60: return "右 ⇧ Shift"
        case 57: return "⇪ CapsLock"
        case 58: return "左 ⌥ Option"
        case 61: return "右 ⌥ Option"
        case 59: return "左 ⌃ Control"
        case 62: return "右 ⌃ Control"
        case 63: return "Fn / 🌐"
        default: return nil
        }
    }

    private static func localizedDeviceName(_ rawName: String) -> String {
        if rawName == "Apple Internal Keyboard / Trackpad" {
            return "内蔵キーボード"
        }
        return rawName.isEmpty ? "接続中のキーボード" : rawName
    }
}
