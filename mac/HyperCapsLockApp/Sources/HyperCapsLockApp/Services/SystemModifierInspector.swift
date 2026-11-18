import Foundation
import HyperCapsLockCore
import IOKit

/// IOKit Registry から現在接続されているキーボードの修飾キー変更設定を読み取るサービス（入力監視権限不要）。
enum SystemModifierInspector {
    static func detectCapsLockConflicts() -> [CapsLockSystemConflict] {
        let snapshots = readActiveKeyboardModifierSnapshots()
        return ModifierConflictDetector.detectConflicts(in: snapshots)
    }

    private static func readActiveKeyboardModifierSnapshots() -> [KeyboardModifierDeviceSnapshot] {
        var iterator: io_iterator_t = 0
        let status = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDEventService"),
            &iterator
        )
        guard status == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        var snapshots: [KeyboardModifierDeviceSnapshot] = []
        var service = IOIteratorNext(iterator)

        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            guard
                let propsRef = IORegistryEntryCreateCFProperty(
                    service,
                    "HIDEventServiceProperties" as CFString,
                    kCFAllocatorDefault,
                    0
                )?.takeRetainedValue(),
                let props = propsRef as? [String: Any],
                let rawPairs = props["HIDKeyboardModifierMappingPairs"] as? [[String: Any]],
                !rawPairs.isEmpty
            else {
                continue
            }

            var entries: [HidKeyMappingEntry] = []
            for pair in rawPairs {
                guard
                    let srcNum = pair["HIDKeyboardModifierMappingSrc"] as? NSNumber,
                    let dstNum = pair["HIDKeyboardModifierMappingDst"] as? NSNumber
                else {
                    continue
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

        return snapshots
    }
}
