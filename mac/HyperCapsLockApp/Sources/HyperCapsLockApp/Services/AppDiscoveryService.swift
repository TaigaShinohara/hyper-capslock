import AppKit
import Foundation
import HyperCapsLockCore

/// インストール済みアプリケーションを検出し、切り替え候補を自動選定するサービス。
@MainActor
final class AppDiscoveryService {
    func discoverInstalledApps() -> [AppTarget] {
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSString(string: "~/Applications").expandingTildeInPath,
        ]

        let fm = FileManager.default
        var seenBundleIDs = Set<String>()
        var targets: [AppTarget] = []

        for dir in searchDirectories {
            let dirURL = URL(fileURLWithPath: dir, isDirectory: true)
            guard let items = try? fm.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for itemURL in items where itemURL.pathExtension == "app" {
                guard let bundle = Bundle(url: itemURL),
                      let bundleID = bundle.bundleIdentifier,
                      !seenBundleIDs.contains(bundleID)
                else {
                    continue
                }
                seenBundleIDs.insert(bundleID)

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? itemURL.deletingPathExtension().lastPathComponent

                targets.append(
                    AppTarget(
                        name: displayName,
                        bundleIdentifier: bundleID,
                        path: itemURL.path
                    )
                )
            }
        }

        return targets.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// 環境に合わせて Hyper+1 / 2 / 3 の初期おすすめアプリを選ぶ。
    func recommendedDefaults(from installedApps: [AppTarget]) -> (slot1: AppTarget, slot2: AppTarget, slot3: AppTarget) {
        let fallback = HyperConfig()

        let slot1 = firstMatch(
            bundleIDs: [
                KeyCodeCatalog.cursorBundleID,
                KeyCodeCatalog.vsCodeBundleID,
                "dev.zed.Zed",
                "com.apple.dt.Xcode",
            ],
            in: installedApps
        ) ?? fallback.slot1App

        let slot2 = firstMatch(
            bundleIDs: [
                "com.google.Chrome",
                "company.thebrowser.Browser", // Arc
                "com.brave.Browser",
                "com.apple.Safari",
            ],
            in: installedApps
        ) ?? fallback.slot2App

        let slot3 = firstMatch(
            bundleIDs: [
                "com.mitchellh.ghostty",
                "dev.warp.Warp-Stable",
                "com.googlecode.iterm2",
                "com.github.wez.wezterm",
                "com.apple.Terminal",
            ],
            in: installedApps
        ) ?? fallback.slot3App

        return (slot1, slot2, slot3)
    }

    func activate(_ target: AppTarget) {
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: target.bundleIdentifier).first {
            runningApp.activate(options: [.activateAllWindows])
            return
        }

        let appURL: URL?
        if FileManager.default.fileExists(atPath: target.path) {
            appURL = URL(fileURLWithPath: target.path)
        } else {
            appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier)
        }

        guard let url = appURL else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }

    func icon(for target: AppTarget) -> NSImage {
        if FileManager.default.fileExists(atPath: target.path) {
            return NSWorkspace.shared.icon(forFile: target.path)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .applicationBundle)
    }

    private func firstMatch(bundleIDs: [String], in apps: [AppTarget]) -> AppTarget? {
        for id in bundleIDs {
            if let found = apps.first(where: { $0.bundleIdentifier == id }) {
                return found
            }
        }
        return nil
    }
}
