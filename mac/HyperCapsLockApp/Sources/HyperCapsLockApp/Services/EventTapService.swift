import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import HyperCapsLockCore

/// CGEventTap を用いて低レベルでキー入力を受け取り、HyperEngine の判定結果を実行するサービス。
final class EventTapService: @unchecked Sendable {
    private static let syntheticEventTag: Int64 = 0x4859504552 // "HYPER"

    private let engine = HyperEngine()
    private let lock = NSLock()

    private var configSnapshot = HyperConfig()
    private var frontmostBundleIDSnapshot: String?
    private var shouldReportModifierHintSnapshot = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    var onDecisionFeedback: (@Sendable (Bool, HyperFeedbackEvent?) -> Void)?
    var onModifierKeyObserved: (@Sendable (Int) -> Void)?
    var onActivateApp: (@Sendable (AppTarget) -> Void)?
    var onSnapWindow: (@Sendable (WindowSnapSide) -> Void)?

    /// アクセシビリティ権限が付与されているか。
    static func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func updateConfig(_ config: HyperConfig) {
        lock.lock()
        let wasEnabled = configSnapshot.isEnabled
        configSnapshot = config
        var flushActions: [HyperAction] = []
        if wasEnabled && !config.isEnabled {
            flushActions = engine.reset()
        }
        lock.unlock()

        if !flushActions.isEmpty {
            executeActions(flushActions)
        }
    }

    func updateFrontmostBundleIdentifier(_ bundleID: String?) {
        lock.lock()
        frontmostBundleIDSnapshot = bundleID
        lock.unlock()
    }

    func updateShouldReportModifierHint(_ shouldReport: Bool) {
        lock.lock()
        shouldReportModifierHintSnapshot = shouldReport
        lock.unlock()
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
        guard Self.isAccessibilityTrusted(prompt: false) else { return false }

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { proxy, type, event, refcon in
                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let service = Unmanaged<EventTapService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleCGEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: refcon
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        return true
    }

    func stop() {
        lock.lock()
        let flushActions = engine.reset()
        lock.unlock()

        if !flushActions.isEmpty {
            executeActions(flushActions)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }

    // MARK: - Event Handling

    private func handleCGEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // 自分が送出した合成イベントは再処理せず通す
        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventTag {
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            lock.lock()
            let shouldReport = shouldReportModifierHintSnapshot
            lock.unlock()
            if shouldReport {
                let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                onModifierKeyObserved?(keyCode)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let kind: KeyEventKind = (type == .keyDown) ? .keyDown : .keyUp
        let nowMs = Int64(ProcessInfo.processInfo.systemUptime * 1000.0)

        lock.lock()
        let config = configSnapshot
        let frontBundleID = frontmostBundleIDSnapshot
        let input = HyperKeyInput(
            keyCode: keyCode,
            kind: kind,
            isAutorepeat: isAutorepeat,
            timestampMs: nowMs,
            frontmostBundleIdentifier: frontBundleID,
            modifierBits: event.flags.rawValue
        )
        let decision = engine.handle(input, config: config)
        lock.unlock()

        if !decision.actions.isEmpty {
            executeActions(decision.actions)
        }

        if decision.feedback != nil || decision.shouldConsume {
            onDecisionFeedback?(decision.isHoldingHyper, decision.feedback)
        }

        return decision.shouldConsume ? nil : Unmanaged.passUnretained(event)
    }

    private func executeActions(_ actions: [HyperAction]) {
        for action in actions {
            switch action {
            case let .sendKey(keyCode, kind, modifiers):
                postSyntheticKey(keyCode: keyCode, kind: kind, modifiers: modifiers)
            case let .activateApp(target):
                onActivateApp?(target)
            case let .snapWindow(side):
                onSnapWindow?(side)
            case .blocked:
                break
            }
        }
    }

    private func postSyntheticKey(
        keyCode: Int,
        kind: KeyEventKind,
        modifiers: HyperModifierFlags
    ) {
        guard let cgEvent = CGEvent(
            keyboardEventSource: eventSource,
            virtualKey: CGKeyCode(keyCode),
            keyDown: kind == .keyDown
        ) else {
            return
        }

        var flags: CGEventFlags = []
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }

        cgEvent.flags = flags
        cgEvent.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventTag)
        cgEvent.post(tap: .cghidEventTap)
    }
}
