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

/// Hyper CapsLock の設定モデル。
public struct HyperConfig: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var onboardingStep: OnboardingStep
    public var starterEnabled: Bool
    public var windowSplitEnabled: Bool
    public var navigationEnabled: Bool
    public var jisEisuuEnabled: Bool
    public var passthroughUnassignedAsFourModifiers: Bool
    public var tapThresholdMs: Int
    public var launchAtLogin: Bool

    public var slot1App: AppTarget
    public var slot2App: AppTarget
    public var slot3App: AppTarget

    public init(
        isEnabled: Bool = true,
        onboardingStep: OnboardingStep = .permissions,
        starterEnabled: Bool = false,
        windowSplitEnabled: Bool = false,
        navigationEnabled: Bool = false,
        jisEisuuEnabled: Bool = false,
        passthroughUnassignedAsFourModifiers: Bool = false,
        tapThresholdMs: Int = 200,
        launchAtLogin: Bool = false,
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
        self.jisEisuuEnabled = jisEisuuEnabled
        self.passthroughUnassignedAsFourModifiers = passthroughUnassignedAsFourModifiers
        self.tapThresholdMs = tapThresholdMs
        self.launchAtLogin = launchAtLogin
        self.slot1App = slot1App
        self.slot2App = slot2App
        self.slot3App = slot3App
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
