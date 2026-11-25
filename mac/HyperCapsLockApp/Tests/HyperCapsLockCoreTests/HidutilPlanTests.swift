import Foundation
import Testing
@testable import HyperCapsLockCore

@Suite("Per-keyboard CapsLock mapping")
struct HidutilPlanTests {
    private let selected: UInt64 = 10
    private let other: UInt64 = 11
    private let f19: UInt64 = KeyCodeCatalog.hidF19
    private let f20: UInt64 = KeyCodeCatalog.hidF20
    private let original = HidKeyMappingEntry(src: 0x7000000E0, dst: 0x7000000E3)
    private let unrelated = HidKeyMappingEntry(src: 0x7000000E2, dst: 0x7000000E6)

    @Test("Same-model keyboard services and independent changes keep their own mappings")
    func preservesIndependentMappings() throws {
        let fixture = Fixture([selected: [original], other: [unrelated]])
        try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        let owned = HidKeyMappingEntry(src: KeyCodeCatalog.hidCapsLock, dst: f19)
        #expect(fixture.store.entries[selected] == [owned, original])
        #expect(fixture.store.entries[other] == [unrelated])
        fixture.store.entries[selected]?.append(unrelated)
        try fixture.plan.validateActiveMapping()
        try fixture.plan.restore()
        #expect(fixture.store.entries[selected] == [original, unrelated])
        #expect(fixture.store.entries[other] == [unrelated])
        #expect(fixture.store.writes == [selected, selected])
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("Existing CapsLock source and destination each block a write")
    func rejectsCapsLockAssignments() {
        for entry in [
            HidKeyMappingEntry(src: KeyCodeCatalog.hidCapsLock, dst: original.dst),
            HidKeyMappingEntry(src: original.src, dst: KeyCodeCatalog.hidCapsLock),
        ] {
            let fixture = Fixture([selected: [entry], other: []])
            #expect(throws: HidMappingError.capsLockAssigned) {
                try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
            }
            #expect(fixture.store.writes.isEmpty)
            #expect(!fixture.plan.hasPendingRestoration)
        }
    }

    @Test("A reserved key collision on another service can be resolved by changing the reservation")
    func rejectsDestinationConflictOnOtherKeyboard() throws {
        let assigned = HidKeyMappingEntry(src: original.src, dst: f19)
        let fixture = Fixture([selected: [], other: [assigned]])
        #expect(throws: HidMappingError.reservedKeyAssigned) {
            try fixture.plan.preflight(deviceID: selected, reservedUsage: f19)
        }
        try fixture.plan.apply(deviceID: selected, reservedUsage: f20)
        #expect(fixture.store.entries[other] == [assigned])
        #expect(fixture.store.writes == [selected])
    }

    @Test("A missing keyboard, unreadable mapping, or unsupported F18 reservation causes no write")
    func failsClosed() {
        let fixture = Fixture([selected: []])
        #expect(throws: HidMappingError.unsupportedReservedKey) {
            try fixture.plan.apply(deviceID: selected, reservedUsage: KeyCodeCatalog.hidF18)
        }
        #expect(throws: HidMappingError.keyboardUnavailable) {
            try fixture.plan.apply(deviceID: other, reservedUsage: f19)
        }
        fixture.store.unreadable = true
        #expect(throws: HidMappingError.unreadableMappings) {
            try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        }
        #expect(fixture.store.writes.isEmpty)
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("A change after the initial snapshot blocks even a compatible newer mapping")
    func recheckAbortsOnDrift() {
        let fixture = Fixture([selected: [original]])
        fixture.journal.onSave = { [store = fixture.store, selected, unrelated] in
            store.entries[selected] = [unrelated]
        }
        #expect(throws: HidMappingError.mappingChanged) {
            try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        }
        #expect(fixture.store.entries[selected] == [unrelated])
        #expect(fixture.store.writes.isEmpty)
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("A replaced CapsLock mapping is never re-applied or removed")
    func respectsExternalReplacement() throws {
        let fixture = Fixture([selected: []])
        try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        let replacement = HidKeyMappingEntry(src: KeyCodeCatalog.hidCapsLock, dst: unrelated.dst)
        fixture.store.entries[selected] = [replacement]
        #expect(throws: HidMappingError.mappingChanged) {
            try fixture.plan.validateActiveMapping()
        }
        try fixture.plan.restore()
        #expect(fixture.store.entries[selected] == [replacement])
        #expect(fixture.store.writes == [selected])
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("A new collision blocks active use, then restoring keeps the other service's change")
    func detectsNewCollision() throws {
        let fixture = Fixture([selected: [], other: []])
        try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        let collision = HidKeyMappingEntry(src: f19, dst: original.dst)
        fixture.store.entries[other] = [collision]
        #expect(throws: HidMappingError.reservedKeyAssigned) {
            try fixture.plan.validateActiveMapping()
        }
        try fixture.plan.restore()
        #expect(fixture.store.entries[other] == [collision])
    }

    @Test("Failed restore retains the pending journal and succeeds once writable")
    func retriesFailedRestore() throws {
        let fixture = Fixture([selected: [original]])
        try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        fixture.store.ignoreWrites = true
        #expect(throws: HidMappingError.writeUnverified) { try fixture.plan.restore() }
        #expect(fixture.plan.hasPendingRestoration)
        fixture.store.ignoreWrites = false
        try fixture.plan.restore()
        #expect(fixture.store.entries[selected] == [original])
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("An unconfirmed write recovers only when the entire expected mapping still matches")
    func restoresUnconfirmedWriteOnlyWhenUnambiguous() throws {
        let fixture = Fixture([selected: [original]])
        fixture.journal.rejectConfirmation = true
        #expect(throws: HidMappingError.journalUnavailable) {
            try fixture.plan.apply(deviceID: selected, reservedUsage: f20)
        }
        #expect(fixture.plan.hasPendingRestoration)
        fixture.store.entries[selected]?.append(unrelated)
        #expect(throws: HidMappingError.restorationPending) { try fixture.plan.restore() }
        #expect(fixture.plan.hasPendingRestoration)
        #expect(fixture.store.writes == [selected])
        fixture.store.entries[selected]?.removeLast()
        try fixture.plan.restore()
        #expect(fixture.store.entries[selected] == [original])
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("Reused service IDs after a reboot never receive writes from the previous journal")
    func neverWritesAcrossBootSessions() throws {
        let fixture = Fixture([selected: []])
        try fixture.plan.apply(deviceID: selected, reservedUsage: f20)
        fixture.boot.id = UUID()
        try fixture.plan.restore()
        #expect(fixture.store.writes == [selected])
        #expect(!fixture.plan.hasPendingRestoration)
    }

    @Test("Legacy F18 detection never writes an old or external assignment")
    func treatsLegacyRowsAsReadOnly() throws {
        let legacy = HidutilPlan.capsLockToF18Entry
        let fixture = Fixture([selected: [legacy], other: [original]])
        #expect(try fixture.plan.legacyMappingNeedsAttention(wasActive: true))
        #expect(try !fixture.plan.legacyMappingNeedsAttention(wasActive: false))
        try fixture.plan.restore()
        #expect(fixture.store.entries[selected] == [legacy])
        #expect(fixture.store.writes.isEmpty)
    }

    @Test("Duplicate mapping sources are rejected before changes")
    func rejectsAmbiguousMappingRows() {
        let fixture = Fixture([selected: [original, original]])
        #expect(throws: HidMappingError.unreadableMappings) {
            try fixture.plan.apply(deviceID: selected, reservedUsage: f19)
        }
        #expect(fixture.store.writes.isEmpty)
    }

    private struct Fixture {
        let store: FakeMappingStore
        let journal: FakeJournalStore
        let boot: BootSession
        let plan: HidutilPlan

        init(_ entries: [UInt64: [HidKeyMappingEntry]]) {
            let store = FakeMappingStore(entries)
            let journal = FakeJournalStore()
            let boot = BootSession()
            self.store = store
            self.journal = journal
            self.boot = boot
            self.plan = HidutilPlan(store: store, journalStore: journal, bootSession: { boot.id })
        }
    }

    private final class BootSession {
        var id = UUID()
    }

    private final class FakeMappingStore: HidMappingStore {
        var entries: [UInt64: [HidKeyMappingEntry]]
        var writes: [UInt64] = []
        var unreadable = false
        var ignoreWrites = false

        init(_ entries: [UInt64: [HidKeyMappingEntry]]) {
            self.entries = entries
        }

        func snapshots() throws -> [HidKeyboardSnapshot] {
            if unreadable { throw HidMappingError.unreadableMappings }
            return try entries.map { try HidKeyboardSnapshot(id: $0.key, mappings: $0.value) }
        }

        func snapshot(for id: UInt64) throws -> HidKeyboardSnapshot? {
            if unreadable { throw HidMappingError.unreadableMappings }
            return try entries[id].map { try HidKeyboardSnapshot(id: id, mappings: $0) }
        }

        func setMappings(_ entries: [HidKeyMappingEntry], for id: UInt64) throws {
            writes.append(id)
            if !ignoreWrites { self.entries[id] = entries }
        }
    }

    private final class FakeJournalStore: HidMappingJournalStore {
        var record: HidMappingJournal?
        var rejectConfirmation = false
        var onSave: (() -> Void)?

        func load() throws -> HidMappingJournal? { record }

        func save(_ journal: HidMappingJournal) throws {
            if rejectConfirmation && journal.writeConfirmed { throw HidMappingError.journalUnavailable }
            record = journal
            onSave?()
        }

        func clear() throws { record = nil }
    }
}
