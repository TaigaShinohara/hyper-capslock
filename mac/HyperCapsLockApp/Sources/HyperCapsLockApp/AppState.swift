import AppKit
import Foundation
import HyperCapsLockCore
import Observation
import ServiceManagement

struct RuntimeIssue: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
}

enum HyperRuntimeStatus: Equatable {
    case stopped
    case waitingForPermission
    case waitingForInput
    case running
    case blocked(String)
    case restorationFailed(String)

    var title: String {
        switch self {
        case .stopped: "停止中"
        case .waitingForPermission: "アクセシビリティの許可が必要"
        case .waitingForInput: "キー変換を試せます"
        case .running: "稼働中"
        case .blocked: "キー変換を停止しました"
        case .restorationFailed: "キー割り当てを復元できませんでした"
        }
    }

    var detail: String? {
        switch self {
        case .stopped: nil
        case .waitingForPermission: "許可したあと、アプリに戻って試用または有効化を選んでください。"
        case .waitingForInput: "この画面を前面にして、選んだキーを短く押すと確認できます。"
        case .running: nil
        case let .blocked(message), let .restorationFailed(message): message
        }
    }

    var isOperational: Bool { self == .waitingForInput || self == .running }
}

/// アプリ設定と、実際のキー変換・復元の状態を管理する。
@MainActor
@Observable
final class AppState {
    private static let configStorageKey = "HyperCapsLock.Config.v1"

    var config: HyperConfig {
        didSet {
            saveConfig()
            syncEventTapConfig()
            if config.companionSoundEnabled != oldValue.companionSoundEnabled {
                companionSoundService.setEnabled(config.companionSoundEnabled)
                if config.companionSoundEnabled { previewCompanionSound() }
            }
            if config.launchAtLogin != oldValue.launchAtLogin {
                applyLaunchAtLogin(config.launchAtLogin)
            }
            if config.slot1App != oldValue.slot1App || config.starterEnabled != oldValue.starterEnabled {
                clearStarterTrial()
            }
        }
    }

    private(set) var isAccessibilityTrusted = false
    private(set) var runtimeStatus: HyperRuntimeStatus = .stopped
    private(set) var isHoldingHyper = false
    private(set) var isTriggerVerified = false
    private(set) var isStarterTestVerified = false
    private(set) var isStarterTrialEnabled = false
    private var verifiedSelectionThisSession = false
    var canResumeFromMenu: Bool { verifiedSelectionThisSession && config.onboardingStep == .completed }
    private(set) var selectedKeyboardID: UInt64?
    private(set) var capsLockKeyboards: [CapsLockKeyboard] = []
    private(set) var capsLockConflicts: [CapsLockSystemConflict] = []
    private(set) var capsLockSetupIssue: String?
    private(set) var installedApps: [AppTarget] = []
    private(set) var recentFeedbacks: [HyperFeedbackEvent] = []
    private(set) var runtimeIssues: [RuntimeIssue] = []

    private let hidutilService = HidutilService()
    private let eventTapService = EventTapService()
    private let windowManager = WindowManagerService()
    private let appDiscovery = AppDiscoveryService()
    private let companionSoundService = CompanionSoundService()
    private var permissionTimer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var localKeyMonitor: Any?
    private var escapeTestTag: Int64?
    private var started = false
    private var starterActivation: (target: AppTarget, attempt: UUID)?
    private var starterTimeout: Task<Void, Never>?

    init() {
        config = Self.loadConfig() ?? HyperConfig()
    }

    func bootstrap() {
        guard !started else { return }
        started = true
        installedApps = appDiscovery.discoverInstalledApps()
        if Self.loadConfig() == nil {
            let defaults = appDiscovery.recommendedDefaults(from: installedApps)
            config.slot1App = defaults.slot1
            config.slot2App = defaults.slot2
            config.slot3App = defaults.slot3
        }

        wireCallbacks()
        observeSystemLifecycle()
        observeEscapeTest()
        stop()
        refreshSetup()

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkRuntime() }
        }
    }

    func requestAccessibilityPermission() {
        _ = EventTapService.isAccessibilityTrusted(prompt: true)
        openAccessibilitySettings()
        checkRuntime()
    }

    func openAccessibilitySettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openKeyboardModifierSettings() {
        openSettingsURL("x-apple.systempreferences:com.apple.Keyboard-Settings.extension")
    }

    private func openSettingsURL(_ value: String) {
        if let url = URL(string: value) {
            NSWorkspace.shared.open(url)
        }
    }

    func refreshSetup() {
        checkRuntime()
        refreshLegacyWarning()
        guard config.triggerMode.usesCapsLock else {
            capsLockConflicts = []
            capsLockSetupIssue = nil
            return
        }
        guard !runtimeStatus.isOperational else { return }

        capsLockConflicts = []
        capsLockSetupIssue = nil
        do {
            capsLockKeyboards = try hidutilService.keyboards()
            if selectedKeyboardID == nil, capsLockKeyboards.count == 1 {
                selectedKeyboardID = capsLockKeyboards.first?.id
            }
            guard let selectedKeyboardID else {
                capsLockSetupIssue = capsLockKeyboards.isEmpty ? "キーボードが見つかりません。" : nil
                return
            }
            guard capsLockKeyboards.contains(where: { $0.id == selectedKeyboardID }) else {
                capsLockSetupIssue = "選んだキーボードが見つかりません。一覧から使うキーボードを選び直してください。"
                return
            }
            capsLockConflicts = try SystemModifierInspector.detectCapsLockConflicts(keyboardID: selectedKeyboardID)
            if capsLockConflicts.isEmpty {
                try hidutilService.preflight(deviceID: selectedKeyboardID, reservedUsage: config.capsLockReservedKey.hidUsage)
            }
        } catch {
            capsLockSetupIssue = error.localizedDescription
        }
    }

    func setTriggerMode(_ mode: HyperTriggerMode) {
        guard config.triggerMode != mode, prepareForTriggerChange() else { return }
        config.triggerMode = mode
        refreshSetup()
    }

    func selectKeyboard(_ id: UInt64) {
        guard selectedKeyboardID != id, prepareForTriggerChange() else { return }
        selectedKeyboardID = id
        refreshSetup()
    }

    func setReservedKey(_ key: CapsLockReservedKey) {
        guard config.capsLockReservedKey != key, prepareForTriggerChange() else { return }
        config.capsLockReservedKey = key
        refreshSetup()
    }

    private func prepareForTriggerChange() -> Bool {
        stop()
        if case .restorationFailed = runtimeStatus { return false }
        verifiedSelectionThisSession = false
        return true
    }

    func start() {
        start(reuseVerifiedSelection: false)
    }

    func resumeFromMenu() {
        guard canResumeFromMenu else { return }
        start(reuseVerifiedSelection: true)
    }

    private func start(reuseVerifiedSelection: Bool) {
        guard !runtimeStatus.isOperational else { return }
        stop()
        if case .restorationFailed = runtimeStatus { return }
        refreshSetup()
        guard isAccessibilityTrusted else {
            runtimeStatus = .waitingForPermission
            return
        }
        if config.triggerMode.usesCapsLock {
            if let issue = capsLockSetupIssue {
                runtimeStatus = .blocked(issue)
                return
            }
            guard capsLockConflicts.isEmpty else {
                runtimeStatus = .blocked("選んだキーボードでは CapsLock の既存の割り当てを維持しています。別の方法を選んでください。")
                return
            }
            guard selectedKeyboardID != nil else {
                runtimeStatus = .blocked("CapsLock を使うキーボードを選んでください。")
                return
            }
        }
        guard eventTapService.start() else {
            runtimeStatus = .blocked("キー監視を開始できませんでした。システム設定のアクセシビリティと入力監視を確認してから、もう一度有効にしてください。")
            return
        }

        do {
            if config.triggerMode.usesCapsLock, let selectedKeyboardID {
                try hidutilService.apply(deviceID: selectedKeyboardID, reservedUsage: config.capsLockReservedKey.hidUsage)
            }
        } catch {
            blockRuntime(error.localizedDescription)
            return
        }

        escapeTestTag = eventTapService.beginEscapeTest()
        config.isEnabled = true
        isTriggerVerified = reuseVerifiedSelection && verifiedSelectionThisSession
        runtimeStatus = isTriggerVerified ? .running : .waitingForInput
    }

    func stop() {
        if config.isEnabled { config.isEnabled = false }
        eventTapService.stop()
        companionSoundService.stopPlayback()
        isHoldingHyper = false
        isTriggerVerified = false
        escapeTestTag = nil
        recentFeedbacks = []
        resetStarterTrial()
        do {
            try hidutilService.restore()
            runtimeStatus = .stopped
        } catch {
            runtimeStatus = .restorationFailed(error.localizedDescription)
        }
    }

    func startTrial() {
        start()
        if runtimeStatus.isOperational { config.onboardingStep = .testEsc }
    }

    func restartTrialSetup() {
        stop()
        verifiedSelectionThisSession = false
        config.onboardingStep = .permissions
        refreshSetup()
    }

    func advanceOnboarding(to step: OnboardingStep) {
        if step == .starter && !isTriggerVerified { return }
        config.onboardingStep = step
    }

    func enableStarterTrial() {
        guard runtimeStatus.isOperational, isTriggerVerified else { return }
        isStarterTrialEnabled = true
        syncEventTapConfig()
    }

    func resetStarterTrial() {
        isStarterTrialEnabled = false
        clearStarterTrial()
        syncEventTapConfig()
    }

    func finishOnboarding(keepEnabled: Bool, keepStarter: Bool = true) {
        if keepEnabled && keepStarter && isStarterTrialEnabled && isStarterTestVerified {
            config.starterEnabled = true
        }
        resetStarterTrial()
        if !keepEnabled { stop() }
        config.onboardingStep = .completed
    }

    func reopenOnboarding() {
        restartTrialSetup()
    }

    func retryRuntime() {
        if case .restorationFailed = runtimeStatus {
            stop()
        }
        refreshSetup()
        refreshInstalledApps()
    }

    func refreshInstalledApps() {
        installedApps = appDiscovery.discoverInstalledApps()
    }

    func appIcon(for target: AppTarget) -> NSImage {
        appDiscovery.icon(for: target)
    }

    func openSetupGuide() {
        if let url = URL(string: "https://github.com/TaigaShinohara/hyper-capslock/blob/main/mac/README.md") {
            NSWorkspace.shared.open(url)
        }
    }

    func previewCompanionSound() {
        companionSoundService.playTriggerVoice(ignoringEnabledFlag: true)
    }

    func quitAndRestore() {
        NSApp.terminate(nil)
    }

    func prepareToQuit() -> Bool {
        stop()
        if case .restorationFailed = runtimeStatus { return false }
        return true
    }

    func finishTermination() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Runtime checks

    private func checkRuntime() {
        isAccessibilityTrusted = EventTapService.isAccessibilityTrusted()
        if case .waitingForPermission = runtimeStatus, isAccessibilityTrusted {
            runtimeStatus = .stopped
        }
        guard runtimeStatus.isOperational else { return }
        guard isAccessibilityTrusted, eventTapService.isListening else {
            blockRuntime("キー監視が終了しました。権限を確認してから、有効にし直してください。")
            return
        }
        if config.triggerMode.usesCapsLock, let selectedKeyboardID {
            do {
                try hidutilService.validateActiveMapping()
                let conflicts = try SystemModifierInspector.detectCapsLockConflicts(keyboardID: selectedKeyboardID)
                guard conflicts.isEmpty else {
                    capsLockConflicts = conflicts
                    blockRuntime("macOS の CapsLock 割り当てが変わったため、キー変換を停止しました。")
                    return
                }
            } catch {
                blockRuntime(error.localizedDescription)
            }
        }
    }

    private func blockRuntime(_ detail: String) {
        stop()
        verifiedSelectionThisSession = false
        if case .restorationFailed = runtimeStatus { return }
        runtimeStatus = .blocked(detail)
    }

    private func refreshLegacyWarning() {
        do {
            if try hidutilService.legacyMappingNeedsAttention() {
                setIssue(
                    id: "legacy-mapping",
                    title: "旧版の CapsLock → F18 が残っています",
                    detail: "元の割り当てを安全に特定できないため、その設定は変更していません。以前の設定ツールを確認してください。一時的な変換を解除するには、Mac を再起動してから再確認できます。"
                )
            } else {
                clearIssue("legacy-mapping")
            }
        } catch {
            setIssue(id: "legacy-mapping", title: "旧版の割り当てを確認できませんでした", detail: error.localizedDescription)
        }
    }

    private func wireCallbacks() {
        eventTapService.updateFrontmostBundleIdentifier(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        syncEventTapConfig()
        companionSoundService.setEnabled(config.companionSoundEnabled)

        let soundService = companionSoundService
        eventTapService.onTriggerPressStarted = {
            soundService.playTriggerVoice()
        }

        eventTapService.onDecisionFeedback = { [weak self] holding, feedback in
            Task { @MainActor [weak self] in
                guard let self, self.runtimeStatus.isOperational else { return }
                self.isHoldingHyper = holding
                if let feedback {
                    self.recentFeedbacks = Array(([feedback] + self.recentFeedbacks).prefix(6))
                }
            }
        }

        eventTapService.onActivateApp = { [weak self] target, fromSlotOne in
            Task { @MainActor [weak self] in
                await self?.activateApp(target, fromSlotOne: fromSlotOne)
            }
        }

        eventTapService.onSnapWindow = { [weak self] side in
            Task { @MainActor [weak self] in
                guard let self, self.runtimeStatus.isOperational else { return }
                self.windowManager.snapFrontmostWindow(to: side)
            }
        }
    }

    private func syncEventTapConfig() {
        var effectiveConfig = config
        if config.onboardingStep != .completed {
            effectiveConfig.starterEnabled = config.onboardingStep == .starter && isStarterTrialEnabled
            effectiveConfig.chatShortcutEnabled = false
            effectiveConfig.panelShortcutEnabled = false
            effectiveConfig.windowSplitEnabled = false
            effectiveConfig.navigationEnabled = false
            effectiveConfig.passthroughUnassignedAsFourModifiers = false
        }
        eventTapService.updateConfig(effectiveConfig)
    }

    private func observeEscapeTest() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == KeyCodeCatalog.escape,
                  let receivedTag = event.cgEvent?.getIntegerValueField(.eventSourceUserData) else {
                return event
            }
            let verified = MainActor.assumeIsolated {
                guard let self, self.runtimeStatus == .waitingForInput, self.escapeTestTag == receivedTag else {
                    return false
                }
                self.isTriggerVerified = true
                self.verifiedSelectionThisSession = true
                self.runtimeStatus = .running
                return true
            }
            return verified ? nil : event
        }
    }

    private func activateApp(_ target: AppTarget, fromSlotOne: Bool) async {
        guard runtimeStatus.isOperational else { return }
        let isTest = fromSlotOne && config.onboardingStep == .starter && target == config.slot1App
        let attempt = UUID()
        if isTest {
            clearStarterTrial()
            starterActivation = (target, attempt)
            starterTimeout = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, let self, self.starterActivation?.attempt == attempt else { return }
                self.clearStarterTrial()
                self.setIssue(id: "app-activation", title: "切り替えを確認できませんでした", detail: "「\(target.name)」が前面に来るか確認するか、別のアプリを選んでください。")
            }
        }
        if await appDiscovery.activate(target) {
            if isTest, starterActivation?.attempt == attempt {
                observeFrontmostApp(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
            } else if !isTest {
                clearIssue("app-activation")
            }
        } else if runtimeStatus.isOperational && (!isTest || starterActivation?.attempt == attempt) {
            if isTest { clearStarterTrial() }
            setIssue(id: "app-activation", title: "アプリを開けませんでした", detail: "「\(target.name)」を開けませんでした。設定で別のアプリを選べます。")
        }
    }

    private func clearStarterTrial() {
        starterTimeout?.cancel()
        starterTimeout = nil
        starterActivation = nil
        isStarterTestVerified = false
        clearIssue("app-activation")
    }

    private func observeFrontmostApp(_ bundleID: String?) {
        eventTapService.updateFrontmostBundleIdentifier(bundleID)
        guard let starterActivation, bundleID == starterActivation.target.bundleIdentifier else { return }
        clearStarterTrial()
        isStarterTestVerified = true
    }

    private func observeSystemLifecycle() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            let bundleID = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            MainActor.assumeIsolated { self?.observeFrontmostApp(bundleID) }
        })

        for name in [NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.willSleepNotification] {
            workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    if let self, self.runtimeStatus.isOperational {
                        self.stop()
                    }
                }
            })
        }
    }

    private func setIssue(id: String, title: String, detail: String) {
        clearIssue(id)
        runtimeIssues.append(RuntimeIssue(id: id, title: title, detail: detail))
    }

    private func clearIssue(_ id: String) {
        runtimeIssues.removeAll { $0.id == id }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            clearIssue("launch-at-login")
        } catch {
            setIssue(id: "launch-at-login", title: "ログイン時の起動を変更できませんでした", detail: error.localizedDescription)
        }
    }

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configStorageKey)
        }
    }

    private static func loadConfig() -> HyperConfig? {
        guard let data = UserDefaults.standard.data(forKey: configStorageKey) else { return nil }
        return try? JSONDecoder().decode(HyperConfig.self, from: data)
    }
}
