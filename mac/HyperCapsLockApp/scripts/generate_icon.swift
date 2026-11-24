#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: generate_icon.swift <output-icns-path>\n", stderr)
    exit(1)
}

let outputIcnsPath = CommandLine.arguments[1]
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("HyperCapsLockIcon-\(UUID().uuidString)")
let iconsetDir = tempDir.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

defer {
    try? FileManager.default.removeItem(at: tempDir)
}

let entries: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func renderIcon(pixelSize: Int) -> Data? {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
    guard let rep else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(pixelSize)
    let margin = s * 0.08
    let rect = CGRect(x: margin, y: margin, width: s - margin * 2, height: s - margin * 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: s * 0.22, yRadius: s * 0.22)

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.13, green: 0.18, blue: 0.30, alpha: 1.0),
            NSColor(calibratedRed: 0.22, green: 0.36, blue: 0.68, alpha: 1.0),
        ]
    )
    gradient?.draw(in: path, angle: 65)

    // 内側のキーキャップ枠
    let innerInset = s * 0.17
    let innerRect = CGRect(x: innerInset, y: innerInset, width: s - innerInset * 2, height: s - innerInset * 2)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: s * 0.14, yRadius: s * 0.14)
    NSColor.white.withAlphaComponent(0.14).setFill()
    innerPath.fill()
    NSColor.white.withAlphaComponent(0.35).setStroke()
    innerPath.lineWidth = max(1.0, s * 0.02)
    innerPath.stroke()

    // CapsLock シンボル（⇪）
    let symbol = "⇪"
    let font = NSFont.systemFont(ofSize: s * 0.44, weight: .semibold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let str = NSAttributedString(string: symbol, attributes: attrs)
    let strSize = str.size()
    let strOrigin = CGPoint(
        x: (s - strSize.width) / 2.0,
        y: (s - strSize.height) / 2.0 + s * 0.01
    )
    str.draw(at: strOrigin)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

for entry in entries {
    if let data = renderIcon(pixelSize: entry.size) {
        try data.write(to: iconsetDir.appendingPathComponent(entry.name))
    }
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", outputIcnsPath]
try process.run()
process.waitUntilExit()
if process.terminationStatus != 0 {
    exit(process.terminationStatus)
}
