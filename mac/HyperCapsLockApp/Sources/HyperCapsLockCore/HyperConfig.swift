import Foundation

/// オンボーディングの進行段階。
public enum OnboardingStep: String, Codable, Sendable, CaseIterable {
    case permissions
    case testEsc
    case starter
    case completed
}

/// アプリ切り替えスロット（Hyper+1/2/3）の対象アプリ情報。
public struct AppTarget: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var bundleIdentifier: String
    public var path: String

    public init(name: String, bundleIdentifier: String, path: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
}

/// 使い始めに利用者が選ぶキー。両方を使う設定は旧版の選択を引き継ぐ。
public enum HyperTriggerMode: String, Codable, CaseIterable, Sendable {
    case capsLock
    case eisuu
    case capsLockAndEisuu

    public var title: String {
        switch self {
        case .capsLock: "CapsLock"
        case .eisuu: "英数"
        case .capsLockAndEisuu: "CapsLock と英数"
        }
    }

    public var usesCapsLock: Bool { self != .eisuu }
    public var usesEisuu: Bool { self != .capsLock }
}

/// CapsLock の変換に使うキー。F18 は他の用途にそのまま使える。
public enum CapsLockReservedKey: String, Codable, CaseIterable, Sendable {
    case f19
    case f20

    public var title: String { rawValue.uppercased() }
    public var keyCode: Int { self == .f19 ? KeyCodeCatalog.f19 : KeyCodeCatalog.f20 }
    public var hidUsage: UInt64 { self == .f19 ? KeyCodeCatalog.hidF19 : KeyCodeCatalog.hidF20 }
}

/// Hyper CapsLock の設定モデル。
public struct HyperConfig: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var onboardingStep: OnboardingStep
    public var starterEnabled: Bool
    public var windowSplitEnabled: Bool
    public var navigationEnabled: Bool
    public var triggerMode: HyperTriggerMode
    public var capsLockReservedKey: CapsLockReservedKey
    public var chatShortcutEnabled: Bool
    public var panelShortcutEnabled: Bool
    public var passthroughUnassignedAsFourModifiers: Bool
    public var tapThresholdMs: Int
    public var launchAtLogin: Bool
    public var companionSoundEnabled: Bool

    public var slot1App: AppTarget
    public var slot2App: AppTarget
    public var slot3App: AppTarget

    public init(
        isEnabled: Bool = false,
        onboardingStep: OnboardingStep = .permissions,
        starterEnabled: Bool = false,
        windowSplitEnabled: Bool = false,
        navigationEnabled: Bool = false,
        triggerMode: HyperTriggerMode = .capsLock,
        capsLockReservedKey: CapsLockReservedKey = .f20,
        chatShortcutEnabled: Bool = false,
        panelShortcutEnabled: Bool = false,
        passthroughUnassignedAsFourModifiers: Bool = false,
        tapThresholdMs: Int = 200,
        launchAtLogin: Bool = false,
        companionSoundEnabled: Bool = true,
        slot1App: AppTarget = AppTarget(
            name: "Cursor",
            bundleIdentifier: KeyCodeCatalog.cursorBundleID,
            path: "/Applications/Cursor.app"
        ),
        slot2App: AppTarget = AppTarget(
            name: "Google Chrome",
            bundleIdentifier: "com.google.Chrome",
            path: "/Applications/Google Chrome.app"
        ),
        slot3App: AppTarget = AppTarget(
            name: "Terminal",
            bundleIdentifier: "com.apple.Terminal",
            path: "/System/Applications/Utilities/Terminal.app"
        )
    ) {
        self.isEnabled = isEnabled
        self.onboardingStep = onboardingStep
        self.starterEnabled = starterEnabled
        self.windowSplitEnabled = windowSplitEnabled
        self.navigationEnabled = navigationEnabled
        self.triggerMode = triggerMode
        self.capsLockReservedKey = capsLockReservedKey
        self.chatShortcutEnabled = chatShortcutEnabled
        self.panelShortcutEnabled = panelShortcutEnabled
        self.passthroughUnassignedAsFourModifiers = passthroughUnassignedAsFourModifiers
        self.tapThresholdMs = tapThresholdMs
        self.launchAtLogin = launchAtLogin
        self.companionSoundEnabled = companionSoundEnabled
        self.slot1App = slot1App
        self.slot2App = slot2App
        self.slot3App = slot3App
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case jisEisuuEnabled
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let savedTrigger = try values.decodeIfPresent(HyperTriggerMode.self, forKey: .triggerMode)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let legacyUsesEisuu = try legacy.decodeIfPresent(Bool.self, forKey: .jisEisuuEnabled) ?? false
        let savedStep = try values.decodeIfPresent(OnboardingStep.self, forKey: .onboardingStep)
        let defaults = HyperConfig()
        let starterPreference = try values.decodeIfPresent(Bool.self, forKey: .starterEnabled) ?? defaults.starterEnabled
        // 旧版では試用画面に入るだけで保存されていたため、未完了の試用は引き継がない。
        let savedStarter = savedTrigger == nil && savedStep != .completed ? false : starterPreference
        self.init(
            isEnabled: false,
            onboardingStep: savedStep == .completed ? .completed : .permissions,
            starterEnabled: savedStarter,
            windowSplitEnabled: try values.decodeIfPresent(Bool.self, forKey: .windowSplitEnabled) ?? defaults.windowSplitEnabled,
            navigationEnabled: try values.decodeIfPresent(Bool.self, forKey: .navigationEnabled) ?? defaults.navigationEnabled,
            triggerMode: savedTrigger ?? (legacyUsesEisuu ? .capsLockAndEisuu : .capsLock),
            capsLockReservedKey: try values.decodeIfPresent(CapsLockReservedKey.self, forKey: .capsLockReservedKey) ?? defaults.capsLockReservedKey,
            chatShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .chatShortcutEnabled) ?? savedStarter,
            panelShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .panelShortcutEnabled) ?? savedStarter,
            passthroughUnassignedAsFourModifiers: try values.decodeIfPresent(
                Bool.self, forKey: .passthroughUnassignedAsFourModifiers
            ) ?? defaults.passthroughUnassignedAsFourModifiers,
            tapThresholdMs: try values.decodeIfPresent(Int.self, forKey: .tapThresholdMs) ?? defaults.tapThresholdMs,
            launchAtLogin: try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin,
            companionSoundEnabled: try values.decodeIfPresent(
                Bool.self, forKey: .companionSoundEnabled
            ) ?? defaults.companionSoundEnabled,
            slot1App: try values.decodeIfPresent(AppTarget.self, forKey: .slot1App) ?? defaults.slot1App,
            slot2App: try values.decodeIfPresent(AppTarget.self, forKey: .slot2App) ?? defaults.slot2App,
            slot3App: try values.decodeIfPresent(AppTarget.self, forKey: .slot3App) ?? defaults.slot3App
        )
    }

    public func appTarget(forSlot slot: Int) -> AppTarget {
        switch slot {
        case 1: return slot1App
        case 2: return slot2App
        case 3: return slot3App
        default: return slot1App
        }
    }
}
