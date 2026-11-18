import AppKit
import Foundation
import HyperCapsLockCore
import Observation
import ServiceManagement

/// アプリ全体の状態・サービス連携・永続化・ライフサイクルを統括する Store。
@MainActor
@Observable
final class AppState {
    private static let configStorageKey = "HyperCapsLock.Config.v1"

    var config: HyperConfig {
        didSet {
            saveConfig()
            syncEngineAndServices(previous: oldValue)
        }
    }

    var isAccessibilityTrusted: Bool = false
    var isTapRunning: Bool = false
    var isHidutilApplied: Bool = false
    var isHoldingHyper: Bool = false
    var installedApps: [AppTarget] = []
    var recentFeedbacks: [HyperFeedbackEvent] = []
    var escTestSuccessCount: Int = 0
    var starterTestSuccessCount: Int = 0
    var statusBannerMessage: String?

    private let hidutilService = HidutilService()
    private let eventTapService = EventTapService()
    private let windowManager = WindowManagerService()
    private let appDiscovery = AppDiscoveryService()

    private var permissionTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var hasInitialized = false

    init() {
        let initialConfig = Self.loadConfig() ?? HyperConfig()
        self.config = initialConfig
    }

    func bootstrap() {
        guard !hasInitialized else { return }
        hasInitialized = true

        // 前回クラッシュ等で CapsLock リマップが孤立していた場合に備えてまず整合性を整える
        if !config.isEnabled {
            hidutilService.cleanupOrphanedMappingIfNeeded()
        }

        installedApps = appDiscovery.discoverInstalledApps()
        if Self.loadConfig() == nil {
            let defaults = appDiscovery.recommendedDefaults(from: installedApps)
            config.slot1App = defaults.slot1
            config.slot2App = defaults.slot2
            config.slot3App = defaults.slot3
        }

        wireCallbacks()
        observeSystemLifecycle()
        refreshAccessibilityAndRuntime()
        startPermissionPolling()
    }

    func shutdownSafely() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        eventTapService.stop()
        hidutilService.restoreOriginalMapping(forceClearAll: false)
        isTapRunning = false
        isHidutilApplied = false
        isHoldingHyper = false
    }

    func requestAccessibilityPermission() {
        _ = EventTapService.isAccessibilityTrusted(prompt: true)
        openAccessibilitySettings()
        refreshAccessibilityAndRuntime()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func refreshInstalledApps() {
        installedApps = appDiscovery.discoverInstalledApps()
    }

    func appIcon(for target: AppTarget) -> NSImage {
        appDiscovery.icon(for: target)
    }

    func advanceOnboarding(to step: OnboardingStep) {
        if step == .starter {
            config.starterEnabled = true
        }
        config.onboardingStep = step
    }

    func reopenOnboarding() {
        escTestSuccessCount = 0
        starterTestSuccessCount = 0
        config.onboardingStep = isAccessibilityTrusted ? .testEsc : .permissions
    }

    func emergencyResetCapsLock() {
        config.isEnabled = false
        eventTapService.stop()
        hidutilService.restoreOriginalMapping(forceClearAll: true)
        isTapRunning = false
        isHidutilApplied = hidutilService.isRemapCurrentlyApplied()
        isHoldingHyper = false
        statusBannerMessage = "CapsLock を macOS 標準の動作に戻しました。"
    }

    func toggleEnabled() {
        config.isEnabled.toggle()
    }

    func quitAndRestore() {
        shutdownSafely()
        NSApp.terminate(nil)
    }

    // MARK: - Private

    private func wireCallbacks() {
        let initialFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        eventTapService.updateFrontmostBundleIdentifier(initialFrontmost)
        eventTapService.updateConfig(config)

        eventTapService.onDecisionFeedback = { [weak self] holding, feedback in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isHoldingHyper = holding
                if let feedback {
                    self.recordFeedback(feedback)
                }
            }
        }

        eventTapService.onActivateApp = { [weak self] target in
            Task { @MainActor [weak self] in
                self?.appDiscovery.activate(target)
            }
        }

        eventTapService.onSnapWindow = { [weak self] side in
            Task { @MainActor [weak self] in
                self?.windowManager.snapFrontmostWindow(to: side)
            }
        }
    }

    private func recordFeedback(_ event: HyperFeedbackEvent) {
        recentFeedbacks.insert(event, at: 0)
        if recentFeedbacks.count > 6 {
            recentFeedbacks.removeLast(recentFeedbacks.count - 6)
        }
        if event.isEscTap {
            escTestSuccessCount += 1
        } else {
            starterTestSuccessCount += 1
        }
    }

    private func observeSystemLifecycle() {
        let wsCenter = NSWorkspace.shared.notificationCenter

        let appActivateObs = wsCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleID = app?.bundleIdentifier
            Task { @MainActor [weak self] in
                self?.eventTapService.updateFrontmostBundleIdentifier(bundleID)
            }
        }
        observers.append(appActivateObs)

        // 画面ロック・ユーザー切替時は安全のため一時的に CapsLock を標準に戻す
        let resignObs = wsCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.eventTapService.stop()
                self.hidutilService.restoreOriginalMapping(forceClearAll: false)
                self.isTapRunning = false
                self.isHidutilApplied = false
                self.isHoldingHyper = false
            }
        }
        observers.append(resignObs)

        let becomeObs = wsCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAccessibilityAndRuntime()
            }
        }
        observers.append(becomeObs)

        let wakeObs = wsCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAccessibilityAndRuntime()
            }
        }
        observers.append(wakeObs)
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAccessibilityAndRuntime()
            }
        }
    }

    private func refreshAccessibilityAndRuntime() {
        let trusted = EventTapService.isAccessibilityTrusted(prompt: false)
        let trustChanged = trusted != isAccessibilityTrusted
        isAccessibilityTrusted = trusted

        if trusted && config.onboardingStep == .permissions {
            config.onboardingStep = .testEsc
        }

        if config.isEnabled && trusted {
            if !isTapRunning {
                let started = eventTapService.start()
                isTapRunning = started
                if started {
                    isHidutilApplied = hidutilService.applyCapsLockRemap()
                    statusBannerMessage = nil
                }
            } else if !hidutilService.isRemapCurrentlyApplied() {
                isHidutilApplied = hidutilService.applyCapsLockRemap()
            }
        } else {
            if isTapRunning {
                eventTapService.stop()
                isTapRunning = false
            }
            if isHidutilApplied {
                hidutilService.restoreOriginalMapping(forceClearAll: false)
                isHidutilApplied = false
            }
            if trustChanged && !trusted && config.isEnabled {
                statusBannerMessage = "アクセシビリティ権限がオフになったため停止しました。"
            }
        }
    }

    private func syncEngineAndServices(previous: HyperConfig) {
        eventTapService.updateConfig(config)

        if previous.isEnabled != config.isEnabled {
            refreshAccessibilityAndRuntime()
        }

        if previous.launchAtLogin != config.launchAtLogin {
            applyLaunchAtLogin(config.launchAtLogin)
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return
        }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            statusBannerMessage = "ログイン時の起動設定を変更できませんでした（\(error.localizedDescription)）。"
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configStorageKey)
        }
    }

    private static func loadConfig() -> HyperConfig? {
        guard
            let data = UserDefaults.standard.data(forKey: configStorageKey),
            let decoded = try? JSONDecoder().decode(HyperConfig.self, from: data)
        else {
            return nil
        }
        return decoded
    }
}
