import Foundation
import HyperCapsLockCore
import IOKit

/// IOKit Registry から現在接続されているキーボードの修飾キー変更設定を読み取るサービス（入力監視権限不要）。
enum SystemModifierInspector {
    static func detectCapsLockConflicts(keyboardID: UInt64) throws -> [CapsLockSystemConflict] {
        let snapshots = try readActiveKeyboardModifierSnapshots(keyboardID: keyboardID)
        return ModifierConflictDetector.detectConflicts(in: snapshots)
    }

    private struct InspectionUnavailable: LocalizedError {
        var errorDescription: String? { "選んだキーボードの macOS 修飾キー設定を確認できませんでした。再接続して再確認してください。" }
    }

    private static func readActiveKeyboardModifierSnapshots(keyboardID: UInt64) throws -> [KeyboardModifierDeviceSnapshot] {
        var iterator: io_iterator_t = 0
        let status = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDEventService"),
            &iterator
        )
        guard status == KERN_SUCCESS else { throw InspectionUnavailable() }
        defer { IOObjectRelease(iterator) }

        var snapshots: [KeyboardModifierDeviceSnapshot] = []
        var service = IOIteratorNext(iterator)
        var foundKeyboard = false

        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var registryID: UInt64 = 0
            guard IORegistryEntryGetRegistryEntryID(service, &registryID) == KERN_SUCCESS, registryID == keyboardID else {
                continue
            }

            foundKeyboard = true
            guard let rawProperties = IORegistryEntryCreateCFProperty(
                service,
                "HIDEventServiceProperties" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() else { continue }
            guard let properties = rawProperties as? [String: Any] else { throw InspectionUnavailable() }
            guard let rawMapping = properties["HIDKeyboardModifierMappingPairs"] else { continue }
            guard let rawPairs = rawMapping as? [[String: Any]] else { throw InspectionUnavailable() }

            var entries: [HidKeyMappingEntry] = []
            for pair in rawPairs {
                guard
                    let srcNum = pair["HIDKeyboardModifierMappingSrc"] as? NSNumber,
                    let dstNum = pair["HIDKeyboardModifierMappingDst"] as? NSNumber
                else {
                    throw InspectionUnavailable()
                }
                entries.append(HidKeyMappingEntry(src: srcNum.uint64Value, dst: dstNum.uint64Value))
            }

            guard !entries.isEmpty else { continue }

            let productName = IORegistryEntrySearchCFProperty(
                service,
                kIOServicePlane,
                "Product" as CFString,
                kCFAllocatorDefault,
                IOOptionBits(kIORegistryIterateParents | kIORegistryIterateRecursively)
            ) as? String ?? "キーボード"

            snapshots.append(KeyboardModifierDeviceSnapshot(deviceName: productName, mappings: entries))
        }

        guard foundKeyboard else { throw InspectionUnavailable() }
        return snapshots
    }
}
