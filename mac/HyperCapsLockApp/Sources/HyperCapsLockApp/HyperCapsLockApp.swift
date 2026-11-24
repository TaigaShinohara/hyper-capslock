import AppKit
import HyperCapsLockCore
import SwiftUI

/// メニューバー常駐と専用ウィンドウ表示切り替え（表示時のみ Dock アイコン出現）を管理する AppDelegate。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var appState: AppState?
    var openWindowAction: (() -> Void)?
    private var closeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            Task { @MainActor [weak self] in
                self?.handleWindowClosing(closingWindow)
            }
        }
        appState?.bootstrap()
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
        }
        appState?.shutdownSafely()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        openWindowAction?()
        DispatchQueue.main.async {
            for window in NSApp.windows where window.identifier?.rawValue == "main" || window.title == "Hyper CapsLock" {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func handleWindowClosing(_ closingWindow: NSWindow) {
        DispatchQueue.main.async {
            let hasVisibleMain = NSApp.windows.contains { window in
                window !== closingWindow
                    && window.isVisible
                    && (window.identifier?.rawValue == "main" || window.title == "Hyper CapsLock")
            }
            let closingIsMain = closingWindow.identifier?.rawValue == "main" || closingWindow.title == "Hyper CapsLock"
            if closingIsMain && !hasVisibleMain {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

@main
struct HyperCapsLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var appState = AppState()

    var body: some Scene {
        Window("Hyper CapsLock", id: "main") {
            Group {
                if appState.config.onboardingStep == .completed {
                    MainControlView(appState: appState)
                } else {
                    OnboardingView(appState: appState)
                }
            }
            .onAppear {
                appDelegate.appState = appState
                appDelegate.openWindowAction = { openWindow(id: "main") }
                appState.bootstrap()
            }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView(appState: appState) {
                appDelegate.appState = appState
                appDelegate.openWindowAction = { openWindow(id: "main") }
                appDelegate.showMainWindow()
            }
        } label: {
            Image(systemName: menuBarSymbolName)
        }
    }

    private var menuBarSymbolName: String {
        if !appState.config.isEnabled {
            return "capslock"
        }
        if !appState.isAccessibilityTrusted {
            return "exclamationmark.triangle"
        }
        return appState.isHoldingHyper ? "command.square.fill" : "capslock.fill"
    }
}
