import Darwin
import Foundation
import HyperCapsLockCore
import IOKit.hid
import IOKit.hidsystem

struct CapsLockKeyboard: Identifiable, Equatable {
    let id: UInt64
    let name: String
}

/// Owns one scoped CapsLock mapping through an individual HID service.
@MainActor
final class HidutilService {
    private static let legacyActiveKey = "HyperCapsLock.IsHidMappingActive"

    private let defaults: UserDefaults
    private let store: SystemHidMappingStore
    private let plan: HidutilPlan
    private let journalStore: FileHidMappingJournalStore

    init(defaults: UserDefaults = .standard) {
        let store = SystemHidMappingStore()
        let journalStore = FileHidMappingJournalStore()
        self.defaults = defaults
        self.store = store
        self.journalStore = journalStore
        self.plan = HidutilPlan(
            store: store,
            journalStore: journalStore,
            bootSession: Self.readBootSession
        )
    }

    var hasPendingRestoration: Bool { plan.hasPendingRestoration }

    func keyboards() throws -> [CapsLockKeyboard] {
        try store.keyboards()
    }

    func preflight(deviceID: UInt64, reservedUsage: UInt64) throws {
        try plan.preflight(deviceID: deviceID, reservedUsage: reservedUsage)
    }

    func apply(deviceID: UInt64, reservedUsage: UInt64) throws {
        try journalStore.withMutationLock {
            try plan.apply(deviceID: deviceID, reservedUsage: reservedUsage)
        }
    }

    func validateActiveMapping() throws {
        try plan.validateActiveMapping()
    }

    func restore() throws {
        guard plan.hasPendingRestoration else { return }
        try journalStore.withMutationLock {
            try plan.restore()
        }
    }

    func legacyMappingNeedsAttention() throws -> Bool {
        try plan.legacyMappingNeedsAttention(wasActive: defaults.bool(forKey: Self.legacyActiveKey))
    }

    private nonisolated static func readBootSession() throws -> UUID {
        var length = 37
        var bytes = [UInt8](repeating: 0, count: length)
        let result = bytes.withUnsafeMutableBytes { buffer in
            sysctlbyname("kern.bootsessionuuid", buffer.baseAddress, &length, nil, 0)
        }
        guard result == 0, length == 37, bytes.last == 0,
              let id = UUID(uuidString: String(decoding: bytes.dropLast(), as: UTF8.self)) else {
            throw HidMappingError.bootSessionUnavailable
        }
        return id
    }
}

private final class SystemHidMappingStore: HidMappingStore {
    private static let mappingKey = kIOHIDUserKeyUsageMapKey
    private static let sourceKey = kIOHIDKeyboardModifierMappingSrcKey
    private static let destinationKey = kIOHIDKeyboardModifierMappingDstKey
    private let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)

    func keyboards() throws -> [CapsLockKeyboard] {
        let services = try keyboardServices()
        let keyboards = services.map { id, service in
            let product = IOHIDServiceClientCopyProperty(service, kIOHIDProductKey as CFString) as? String
            let name = product.flatMap { $0.isEmpty ? nil : $0 } ?? "キーボード"
            return CapsLockKeyboard(id: id, name: name)
        }
        let groups = Dictionary(grouping: keyboards, by: \.name)
        return keyboards.map { keyboard in
            guard groups[keyboard.name, default: []].count > 1 else { return keyboard }
            let serviceID = String(keyboard.id, radix: 16, uppercase: true)
            return CapsLockKeyboard(id: keyboard.id, name: "\(keyboard.name)（\(serviceID)）")
        }.sorted {
            $0.name == $1.name ? $0.id < $1.id : $0.name < $1.name
        }
    }

    func snapshots() throws -> [HidKeyboardSnapshot] {
        try keyboardServices().map { id, service in
            try readSnapshot(service, id: id)
        }
    }

    func snapshot(for id: UInt64) throws -> HidKeyboardSnapshot? {
        guard let service = try keyboardServices()[id] else { return nil }
        return try readSnapshot(service, id: id)
    }

    func setMappings(_ entries: [HidKeyMappingEntry], for id: UInt64) throws {
        guard let service = try keyboardServices()[id] else { throw HidMappingError.keyboardUnavailable }
        let value = entries.map {
            [Self.sourceKey: NSNumber(value: $0.src), Self.destinationKey: NSNumber(value: $0.dst)]
        }
        guard IOHIDServiceClientSetProperty(service, Self.mappingKey as CFString, value as CFArray) else {
            throw HidMappingError.writeUnverified
        }
    }

    private func keyboardServices() throws -> [UInt64: IOHIDServiceClient] {
        guard let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] else {
            throw HidMappingError.unreadableMappings
        }
        var keyboards: [UInt64: IOHIDServiceClient] = [:]
        for service in services where IOHIDServiceClientConformsTo(
            service, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)
        ) != 0 {
            guard let id = Self.readUnsignedNumber(IOHIDServiceClientGetRegistryID(service)),
                  id != 0, keyboards[id] == nil else {
                throw HidMappingError.unreadableMappings
            }
            keyboards[id] = service
        }
        return keyboards
    }

    private func readSnapshot(_ service: IOHIDServiceClient, id: UInt64) throws -> HidKeyboardSnapshot {
        if let property = IOHIDServiceClientCopyProperty(service, Self.mappingKey as CFString) {
            return try decodeSnapshot(property, id: id)
        }

        // Apple documents null as an unset mapping. Confirm the same service is alive
        // and responds to property reads before treating null as an empty array.
        guard let liveService = try keyboardServices()[id],
              IOHIDServiceClientCopyProperty(liveService, kIOHIDPrimaryUsagePageKey as CFString) != nil else {
            throw HidMappingError.unreadableMappings
        }
        if let property = IOHIDServiceClientCopyProperty(liveService, Self.mappingKey as CFString) {
            return try decodeSnapshot(property, id: id)
        }
        return try HidKeyboardSnapshot(id: id, mappings: [])
    }

    private func decodeSnapshot(_ property: CFTypeRef, id: UInt64) throws -> HidKeyboardSnapshot {
        guard let rows = property as? [[String: Any]] else { throw HidMappingError.unreadableMappings }
        let entries = try rows.map { row in
            guard row.count == 2,
                  let source = Self.readUnsignedNumber(row[Self.sourceKey]),
                  let destination = Self.readUnsignedNumber(row[Self.destinationKey]) else {
                throw HidMappingError.unreadableMappings
            }
            return HidKeyMappingEntry(src: source, dst: destination)
        }
        return try HidKeyboardSnapshot(id: id, mappings: entries)
    }

    private static func readUnsignedNumber(_ value: Any?) -> UInt64? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              "cCsSiIlLqQ".contains(String(cString: number.objCType)) else { return nil }
        return UInt64(number.stringValue)
    }
}

private struct FileHidMappingJournalStore: HidMappingJournalStore {
    private let fileManager = FileManager.default

    func withMutationLock(_ operation: () throws -> Void) throws {
        let folder = try fileURL().deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw HidMappingError.journalUnavailable
        }
        let lock = folder.appendingPathComponent("caps-lock-mapping.lock")
        let descriptor = open(lock.path, O_CREAT | O_CLOEXEC | O_NOFOLLOW | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw HidMappingError.journalUnavailable }
        defer { close(descriptor) }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            throw errno == EWOULDBLOCK ? HidMappingError.restorationPending : HidMappingError.journalUnavailable
        }
        try operation()
    }

    func load() throws -> HidMappingJournal? {
        do {
            let data = try Data(contentsOf: fileURL())
            return try JSONDecoder().decode(HidMappingJournal.self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        } catch {
            throw HidMappingError.journalUnavailable
        }
    }

    func save(_ journal: HidMappingJournal) throws {
        do {
            try JSONEncoder().encode(journal).write(to: fileURL(), options: .atomic)
        } catch {
            throw HidMappingError.journalUnavailable
        }
    }

    func clear() throws {
        do {
            try fileManager.removeItem(at: fileURL())
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        } catch {
            throw HidMappingError.journalUnavailable
        }
    }

    private func fileURL() throws -> URL {
        guard let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw HidMappingError.journalUnavailable
        }
        return root.appendingPathComponent("HyperCapsLock", isDirectory: true)
            .appendingPathComponent("caps-lock-mapping-v1.json")
    }
}
