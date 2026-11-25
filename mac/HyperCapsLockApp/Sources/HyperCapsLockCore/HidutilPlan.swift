import Foundation

public struct HidKeyMappingEntry: Codable, Equatable, Sendable {
    public let src: UInt64
    public let dst: UInt64

    enum CodingKeys: String, CodingKey {
        case src = "HIDKeyboardModifierMappingSrc"
        case dst = "HIDKeyboardModifierMappingDst"
    }

    public init(src: UInt64, dst: UInt64) {
        self.src = src
        self.dst = dst
    }

    fileprivate func uses(_ usage: UInt64) -> Bool {
        src == usage || dst == usage
    }
}

public struct HidKeyboardSnapshot {
    public let id: UInt64
    public let mappings: [HidKeyMappingEntry]

    public init(id: UInt64, mappings: [HidKeyMappingEntry]) throws {
        guard Set(mappings.map(\.src)).count == mappings.count else {
            throw HidMappingError.unreadableMappings
        }
        self.id = id
        self.mappings = mappings.sorted { $0.src < $1.src }
    }
}

public protocol HidMappingStore {
    func snapshots() throws -> [HidKeyboardSnapshot]
    /// A nil result means the service is no longer listed. An unreadable mapping throws.
    func snapshot(for id: UInt64) throws -> HidKeyboardSnapshot?
    func setMappings(_ entries: [HidKeyMappingEntry], for id: UInt64) throws
}

public struct HidMappingJournal: Codable {
    public fileprivate(set) var writeConfirmed = false
    fileprivate let bootSession: UUID
    fileprivate let serviceID: UInt64
    fileprivate let ownedEntry: HidKeyMappingEntry
    fileprivate let before: [HidKeyMappingEntry]
}

public protocol HidMappingJournalStore {
    func load() throws -> HidMappingJournal?
    func save(_ journal: HidMappingJournal) throws
    func clear() throws
}

public enum HidMappingError: Error, LocalizedError, Equatable {
    case keyboardUnavailable
    case unreadableMappings
    case capsLockAssigned
    case reservedKeyAssigned
    case unsupportedReservedKey
    case bootSessionUnavailable
    case journalUnavailable
    case restorationPending
    case mappingChanged
    case writeUnverified

    public var errorDescription: String? {
        switch self {
        case .keyboardUnavailable:
            "選択したキーボードを確認できません。接続を確認してください。"
        case .unreadableMappings:
            "キーボードの割り当てを読み取れませんでした。"
        case .capsLockAssigned:
            "選択したキーボードで CapsLock に関わる割り当てがすでに使われています。"
        case .reservedKeyAssigned:
            "予約するファンクションキーは、接続中のキーボードですでに割り当てに使われています。"
        case .unsupportedReservedKey:
            "予約キーには F19 または F20 を選択してください。"
        case .bootSessionUnavailable:
            "現在の起動セッションを確認できませんでした。"
        case .journalUnavailable:
            "割り当ての復元記録を確認できませんでした。"
        case .restorationPending:
            "前回の割り当ての状態を確認できません。復元を再試行するか、Mac を再起動してください。"
        case .mappingChanged:
            "キーボードの割り当てが変更されたため停止しました。"
        case .writeUnverified:
            "キーボードの割り当てへの変更を確認できませんでした。"
        }
    }
}

/// Per-service read/modify/write with a journal saved before requesting a change.
public final class HidutilPlan {
    public static let capsLockToF18Entry = HidKeyMappingEntry(
        src: KeyCodeCatalog.hidCapsLock,
        dst: KeyCodeCatalog.hidF18
    )

    private let store: any HidMappingStore
    private let journalStore: any HidMappingJournalStore
    private let bootSession: () throws -> UUID

    public init(
        store: any HidMappingStore,
        journalStore: any HidMappingJournalStore,
        bootSession: @escaping () throws -> UUID
    ) {
        self.store = store
        self.journalStore = journalStore
        self.bootSession = bootSession
    }

    public var hasPendingRestoration: Bool {
        do {
            return try loadJournal() != nil
        } catch {
            return true
        }
    }

    public func preflight(deviceID: UInt64, reservedUsage: UInt64) throws {
        try ensureJournalIsClear()
        _ = try bootSession()
        _ = try baseline(for: deviceID, reservedUsage: reservedUsage)
    }

    public func apply(deviceID: UInt64, reservedUsage: UInt64) throws {
        try ensureJournalIsClear()
        let session = try bootSession()
        let before = try baseline(for: deviceID, reservedUsage: reservedUsage)
        let entry = HidKeyMappingEntry(src: KeyCodeCatalog.hidCapsLock, dst: reservedUsage)
        var journal = HidMappingJournal(
            bootSession: session,
            serviceID: deviceID,
            ownedEntry: entry,
            before: before
        )
        let expected = try HidKeyboardSnapshot(id: deviceID, mappings: before + [entry]).mappings
        try journalStore.save(journal)

        // Check again after journaling, before replacing the service's mapping array.
        do {
            guard try baseline(for: deviceID, reservedUsage: reservedUsage) == before else {
                throw HidMappingError.mappingChanged
            }
        } catch {
            try journalStore.clear()
            throw error
        }

        try store.setMappings(expected, for: deviceID)
        guard try store.snapshot(for: deviceID)?.mappings == expected else {
            throw HidMappingError.writeUnverified
        }
        journal.writeConfirmed = true
        try journalStore.save(journal)
    }

    public func validateActiveMapping() throws {
        guard let journal = try loadJournal(),
              journal.writeConfirmed,
              try bootSession() == journal.bootSession else {
            throw HidMappingError.mappingChanged
        }

        let snapshots = try readSnapshots()
        guard let current = snapshots.first(where: { $0.id == journal.serviceID }),
              current.mappings.contains(journal.ownedEntry) else {
            throw HidMappingError.mappingChanged
        }

        for snapshot in snapshots {
            for entry in snapshot.mappings {
                if snapshot.id == journal.serviceID {
                    if entry == journal.ownedEntry { continue }
                    if entry.uses(KeyCodeCatalog.hidCapsLock) { throw HidMappingError.capsLockAssigned }
                }
                if entry.uses(journal.ownedEntry.dst) { throw HidMappingError.reservedKeyAssigned }
            }
        }
    }

    public func restore() throws {
        guard let journal = try loadJournal() else { return }
        guard try bootSession() == journal.bootSession else {
            try journalStore.clear()
            return
        }
        guard let current = try store.snapshot(for: journal.serviceID),
              current.mappings.contains(journal.ownedEntry) else {
            try journalStore.clear()
            return
        }

        let remaining = current.mappings.filter { $0 != journal.ownedEntry }
        guard journal.writeConfirmed || remaining == journal.before else {
            // A crash before readback leaves attribution uncertain when other rows also changed.
            throw HidMappingError.restorationPending
        }

        guard try store.snapshot(for: journal.serviceID)?.mappings == current.mappings else {
            throw HidMappingError.mappingChanged
        }
        try store.setMappings(remaining, for: journal.serviceID)
        guard try store.snapshot(for: journal.serviceID)?.mappings == remaining else {
            throw HidMappingError.writeUnverified
        }
        try journalStore.clear()
    }

    public func legacyMappingNeedsAttention(wasActive: Bool) throws -> Bool {
        guard wasActive else { return false }
        return try readSnapshots().contains { $0.mappings.contains(Self.capsLockToF18Entry) }
    }

    private func ensureJournalIsClear() throws {
        guard try loadJournal() == nil else { throw HidMappingError.restorationPending }
    }

    private func loadJournal() throws -> HidMappingJournal? {
        guard let journal = try journalStore.load() else { return nil }
        guard journal.serviceID != 0,
              journal.ownedEntry.src == KeyCodeCatalog.hidCapsLock,
              Self.isSupportedReservedKey(journal.ownedEntry.dst),
              !journal.before.contains(where: {
                  $0.uses(journal.ownedEntry.src) || $0.uses(journal.ownedEntry.dst)
              }),
              let snapshot = try? HidKeyboardSnapshot(id: journal.serviceID, mappings: journal.before),
              snapshot.mappings == journal.before else {
            throw HidMappingError.journalUnavailable
        }
        return journal
    }

    private func readSnapshots() throws -> [HidKeyboardSnapshot] {
        let snapshots = try store.snapshots()
        guard Set(snapshots.map(\.id)).count == snapshots.count else {
            throw HidMappingError.unreadableMappings
        }
        return snapshots
    }

    private func baseline(for deviceID: UInt64, reservedUsage: UInt64) throws -> [HidKeyMappingEntry] {
        guard Self.isSupportedReservedKey(reservedUsage) else {
            throw HidMappingError.unsupportedReservedKey
        }
        let snapshots = try readSnapshots()
        guard let target = snapshots.first(where: { $0.id == deviceID }) else {
            throw HidMappingError.keyboardUnavailable
        }
        guard !target.mappings.contains(where: { $0.uses(KeyCodeCatalog.hidCapsLock) }) else {
            throw HidMappingError.capsLockAssigned
        }
        guard !snapshots.contains(where: { $0.mappings.contains(where: { $0.uses(reservedUsage) }) }) else {
            throw HidMappingError.reservedKeyAssigned
        }
        return target.mappings
    }

    private static func isSupportedReservedKey(_ usage: UInt64) -> Bool {
        usage == KeyCodeCatalog.hidF19 || usage == KeyCodeCatalog.hidF20
    }
}
