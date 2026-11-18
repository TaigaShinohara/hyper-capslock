import Foundation

/// macOS 仮想キーコードおよび HID Usage ID の定数カタログ。
public enum KeyCodeCatalog {
    // MARK: - HID Usage IDs (for hidutil)
    public static let hidCapsLock: UInt64 = 0x700000039
    public static let hidF18: UInt64 = 0x70000006D

    // MARK: - Virtual Key Codes (Carbon HIToolbox)
    public static let f18: Int = 79
    public static let jisEisuu: Int = 102
    public static let escape: Int = 53
    public static let period: Int = 47

    public static let c: Int = 8
    public static let t: Int = 17
    public static let q: Int = 12
    public static let w: Int = 13

    public static let num1: Int = 18
    public static let num2: Int = 19
    public static let num3: Int = 20

    public static let h: Int = 4
    public static let j: Int = 38
    public static let k: Int = 40
    public static let l: Int = 37
    public static let a: Int = 0
    public static let e: Int = 14
    public static let b: Int = 11
    public static let f: Int = 3

    public static let leftArrow: Int = 123
    public static let rightArrow: Int = 124
    public static let downArrow: Int = 125
    public static let upArrow: Int = 126

    // MARK: - Known Bundle Identifiers
    public static let cursorBundleID = "com.todesktop.230313mzl4w4u92"
    public static let vsCodeBundleID = "com.microsoft.VSCode"

    /// ライブモニター表示用の人間可読なキー名。
    public static func displayName(for keyCode: Int) -> String {
        switch keyCode {
        case f18: return "CapsLock"
        case jisEisuu: return "英数"
        case escape: return "Esc"
        case period: return "."
        case c: return "C"
        case t: return "T"
        case q: return "Q"
        case w: return "W"
        case num1: return "1"
        case num2: return "2"
        case num3: return "3"
        case h: return "H"
        case j: return "J"
        case k: return "K"
        case l: return "L"
        case a: return "A"
        case e: return "E"
        case b: return "B"
        case f: return "F"
        case leftArrow: return "←"
        case rightArrow: return "→"
        case downArrow: return "↓"
        case upArrow: return "↑"
        case 49: return "Space"
        case 36: return "Enter"
        default: return "Key(\(keyCode))"
        }
    }
}
