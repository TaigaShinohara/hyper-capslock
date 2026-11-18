import Foundation
import HyperCapsLockCore

/// `/usr/bin/hidutil` を使って CapsLock -> F18 の一時リマップと安全復元を管理するサービス。
final class HidutilService: @unchecked Sendable {
    private enum StorageKey {
        static let baselineMappings = "HyperCapsLock.BaselineHidMappings"
        static let isManagedMappingActive = "HyperCapsLock.IsHidMappingActive"
    }

    private let defaults: UserDefaults
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// CapsLock -> F18 リマップを適用する。既存のユーザー設定は破壊せずに保持する。
    @discardableResult
    func applyCapsLockRemap() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let currentOutput = runHidutil(["property", "--matching", "keyboard", "--get", "UserKeyMapping"]) ?? ""
        let currentEntries = HidutilPlan.parseMappings(fromHidutilOutput: currentOutput)

        // 初回有効化時（まだ自分が適用中でないとき）のみ、自前設定を除いたベースラインを保存
        if !defaults.bool(forKey: StorageKey.isManagedMappingActive) {
            let baseline = HidutilPlan.removingManagedEntry(from: currentEntries)
            saveBaseline(baseline)
        }

        let targetEntries = HidutilPlan.applyingCapsLockToF18(on: loadBaseline())
        guard let json = try? HidutilPlan.encodeUserKeyMappingJSON(targetEntries) else {
            return false
        }

        let success = runHidutil(["property", "--matching", "keyboard", "--set", json]) != nil
        if success {
            defaults.set(true, forKey: StorageKey.isManagedMappingActive)
        }
        return success
    }

    /// 元のキーマッピングへ安全に復元する（強制リセット時はベースラインに関わらず自前エントリを除去）。
    @discardableResult
    func restoreOriginalMapping(forceClearAll: Bool = false) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let targetEntries: [HidKeyMappingEntry]
        if forceClearAll {
            let currentOutput = runHidutil(["property", "--matching", "keyboard", "--get", "UserKeyMapping"]) ?? ""
            let currentEntries = HidutilPlan.parseMappings(fromHidutilOutput: currentOutput)
            targetEntries = HidutilPlan.removingManagedEntry(from: currentEntries)
        } else {
            targetEntries = HidutilPlan.removingManagedEntry(from: loadBaseline())
        }

        guard let json = try? HidutilPlan.encodeUserKeyMappingJSON(targetEntries) else {
            return false
        }

        let success = runHidutil(["property", "--matching", "keyboard", "--set", json]) != nil
        if success {
            defaults.set(false, forKey: StorageKey.isManagedMappingActive)
            defaults.removeObject(forKey: StorageKey.baselineMappings)
        }
        return success
    }

    /// 前回アプリが異常終了して CapsLock -> F18 が残留していた場合に復元する。
    func cleanupOrphanedMappingIfNeeded() {
        lock.lock()
        let wasActive = defaults.bool(forKey: StorageKey.isManagedMappingActive)
        lock.unlock()

        if wasActive {
            restoreOriginalMapping(forceClearAll: true)
        }
    }

    /// 現在の hidutil マッピングに CapsLock -> F18 が含まれているか確認する。
    func isRemapCurrentlyApplied() -> Bool {
        let output = runHidutil(["property", "--matching", "keyboard", "--get", "UserKeyMapping"]) ?? ""
        let entries = HidutilPlan.parseMappings(fromHidutilOutput: output)
        return entries.contains(HidutilPlan.capsLockToF18Entry)
    }

    // MARK: - Private

    private func saveBaseline(_ entries: [HidKeyMappingEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: StorageKey.baselineMappings)
        }
    }

    private func loadBaseline() -> [HidKeyMappingEntry] {
        guard
            let data = defaults.data(forKey: StorageKey.baselineMappings),
            let entries = try? JSONDecoder().decode([HidKeyMappingEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    @discardableResult
    private func runHidutil(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return nil
        }
    }
}
