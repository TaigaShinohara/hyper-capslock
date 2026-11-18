import Foundation

/// hidutil UserKeyMapping の単一エントリ。
public struct HidKeyMappingEntry: Codable, Equatable, Sendable {
    public let src: UInt64
    public let dst: UInt64

    enum CodingKeys: String, CodingKey {
        case src = "HIDKeyboardModifierMappingSrc"
        case dst = "HIDKeyboardModifierMappingDst"
    }

    public init(src: UInt64, dst: UInt64) {
        self.src = src
        self.dst = dst
    }
}

/// hidutil に渡す JSON ペイロード生成および既存マッピング保持ロジック。
public enum HidutilPlan {
    public static let capsLockToF18Entry = HidKeyMappingEntry(
        src: KeyCodeCatalog.hidCapsLock,
        dst: KeyCodeCatalog.hidF18
    )

    /// 既存のマッピング一覧から、本アプリが挿入した CapsLock -> F18 のみを除外した一覧を返す。
    public static func removingManagedEntry(from entries: [HidKeyMappingEntry]) -> [HidKeyMappingEntry] {
        entries.filter { $0 != capsLockToF18Entry }
    }

    /// 既存マッピングを保持したまま、先頭に CapsLock -> F18（同一 Src の古い設定は上書き）を組み立てる。
    public static func applyingCapsLockToF18(on existingEntries: [HidKeyMappingEntry]) -> [HidKeyMappingEntry] {
        let filtered = existingEntries.filter { $0.src != KeyCodeCatalog.hidCapsLock }
        return filtered + [capsLockToF18Entry]
    }

    /// `hidutil property --set` に渡す JSON 文字列を生成する。
    public static func encodeUserKeyMappingJSON(_ entries: [HidKeyMappingEntry]) throws -> String {
        let payload = ["UserKeyMapping": entries]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    /// `hidutil property --matching keyboard --get UserKeyMapping` の出力文字列から
    /// 既存の `HIDKeyboardModifierMappingSrc` / `HIDKeyboardModifierMappingDst` ペアを抽出する。
    public static func parseMappings(fromHidutilOutput output: String) -> [HidKeyMappingEntry] {
        // hidutil --get の出力は OpenStep plist 形式で各エントリが { ... } に格納される
        let blockPattern = #"\{[^\{\}]*\}"#
        guard let blockRegex = try? NSRegularExpression(pattern: blockPattern, options: []) else {
            return []
        }

        let nsOutput = output as NSString
        let matches = blockRegex.matches(in: output, range: NSRange(location: 0, length: nsOutput.length))

        var result: [HidKeyMappingEntry] = []
        for match in matches {
            let block = nsOutput.substring(with: match.range)
            guard
                let src = extractInteger(key: "HIDKeyboardModifierMappingSrc", in: block),
                let dst = extractInteger(key: "HIDKeyboardModifierMappingDst", in: block)
            else {
                continue
            }
            let entry = HidKeyMappingEntry(src: src, dst: dst)
            if !result.contains(entry) {
                result.append(entry)
            }
        }
        return result
    }

    private static func extractInteger(key: String, in text: String) -> UInt64? {
        let pattern = NSRegularExpression.escapedPattern(for: key) + #"\s*=\s*(0x[0-9a-fA-F]+|[0-9]+)\s*;"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)),
              match.numberOfRanges >= 2
        else {
            return nil
        }
        let rawValue = nsText.substring(with: match.range(at: 1))
        if rawValue.lowercased().hasPrefix("0x") {
            return UInt64(rawValue.dropFirst(2), radix: 16)
        }
        return UInt64(rawValue, radix: 10)
    }
}
