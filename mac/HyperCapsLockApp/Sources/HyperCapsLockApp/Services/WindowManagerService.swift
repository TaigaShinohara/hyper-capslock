import AppKit
import ApplicationServices
import Foundation
import HyperCapsLockCore

/// Accessibility API を用いて最前面ウィンドウを左半分・右半分へ配置するサービス。
@MainActor
final class WindowManagerService {
    func snapFrontmostWindow(to side: WindowSnapSide) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        guard let windowElement = focusedWindow(of: appElement) else { return }

        let screens = NSScreen.screens
        guard let primaryScreen = screens.first else { return }
        let primaryHeight = primaryScreen.frame.height

        let currentFrame = readAXFrame(of: windowElement)
        let targetScreen: NSScreen
        if let currentFrame,
           let index = WindowFrameCalculator.bestMatchingScreenIndex(
               forAXWindowFrame: currentFrame,
               screenFramesCocoa: screens.map(\.frame),
               primaryScreenHeight: primaryHeight
           )
        {
            targetScreen = screens[index]
        } else {
            targetScreen = NSScreen.main ?? primaryScreen
        }

        let targetAXFrame = WindowFrameCalculator.axFrame(
            for: targetScreen.visibleFrame,
            primaryScreenHeight: primaryHeight,
            side: side
        )
        applyAXFrame(targetAXFrame, to: windowElement)
    }

    private func focusedWindow(of appElement: AXUIElement) -> AXUIElement? {
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success,
           let ref = focusedRef,
           CFGetTypeID(ref) == AXUIElementGetTypeID()
        {
            return (ref as! AXUIElement)
        }

        var mainRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainRef) == .success,
           let ref = mainRef,
           CFGetTypeID(ref) == AXUIElementGetTypeID()
        {
            return (ref as! AXUIElement)
        }

        return nil
    }

    private func readAXFrame(of windowElement: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posRef) == .success,
            AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let posValue = posRef,
            let sizeValue = sizeRef,
            CFGetTypeID(posValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    private func applyAXFrame(_ rect: CGRect, to windowElement: AXUIElement) {
        var origin = rect.origin
        var size = rect.size

        if let posVal = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
        if let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
        // 最小サイズ制約によるズレ補正のため位置を再適用
        if let posVal = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        }
    }
}
