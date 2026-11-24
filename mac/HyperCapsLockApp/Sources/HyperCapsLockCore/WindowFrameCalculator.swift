import CoreGraphics
import Foundation

/// Cocoa 座標系（左下原点）から Accessibility API 座標系（プライマリ画面左上原点）へのウィンドウ矩形計算。
public enum WindowFrameCalculator {
    /// 指定された画面の可視領域（Cocoa 座標）を基準に、左半分または右半分の AX 座標矩形を計算する。
    /// - Parameters:
    ///   - visibleFrameCocoa: 対象ディスプレイの `visibleFrame`（Cocoa 座標系：左下原点）。
    ///   - primaryScreenHeight: プライマリディスプレイ（`NSScreen.screens[0]`）の高さ。
    ///   - side: 左半分または右半分。
    public static func axFrame(
        for visibleFrameCocoa: CGRect,
        primaryScreenHeight: CGFloat,
        side: WindowSnapSide
    ) -> CGRect {
        let axY = primaryScreenHeight - visibleFrameCocoa.maxY
        let leftWidth = floor(visibleFrameCocoa.width / 2.0)
        let rightWidth = visibleFrameCocoa.width - leftWidth

        switch side {
        case .leftHalf:
            return CGRect(
                x: visibleFrameCocoa.minX,
                y: axY,
                width: leftWidth,
                height: visibleFrameCocoa.height
            )
        case .rightHalf:
            return CGRect(
                x: visibleFrameCocoa.minX + leftWidth,
                y: axY,
                width: rightWidth,
                height: visibleFrameCocoa.height
            )
        }
    }

    /// ウィンドウの現在矩形（AX 座標系）と最も重なり面積が大きいスクリーンのインデックスを返す。
    public static func bestMatchingScreenIndex(
        forAXWindowFrame axFrame: CGRect,
        screenFramesCocoa: [CGRect],
        primaryScreenHeight: CGFloat
    ) -> Int? {
        guard !screenFramesCocoa.isEmpty else { return nil }

        var bestIndex: Int?
        var bestArea: CGFloat = 0

        for (index, cocoaFrame) in screenFramesCocoa.enumerated() {
            let screenAXFrame = CGRect(
                x: cocoaFrame.minX,
                y: primaryScreenHeight - cocoaFrame.maxY,
                width: cocoaFrame.width,
                height: cocoaFrame.height
            )
            let intersection = axFrame.intersection(screenAXFrame)
            if !intersection.isNull {
                let area = intersection.width * intersection.height
                if area > bestArea {
                    bestArea = area
                    bestIndex = index
                }
            }
        }

        if let bestIndex {
            return bestIndex
        }

        // 重なりが無い場合はウィンドウ中心と各スクリーン中心の距離で近い方を選ぶ
        let windowCenter = CGPoint(x: axFrame.midX, y: axFrame.midY)
        var closestIndex = 0
        var minDistance = CGFloat.greatestFiniteMagnitude

        for (index, cocoaFrame) in screenFramesCocoa.enumerated() {
            let screenAXFrame = CGRect(
                x: cocoaFrame.minX,
                y: primaryScreenHeight - cocoaFrame.maxY,
                width: cocoaFrame.width,
                height: cocoaFrame.height
            )
            let center = CGPoint(x: screenAXFrame.midX, y: screenAXFrame.midY)
            let dx = windowCenter.x - center.x
            let dy = windowCenter.y - center.y
            let dist = dx * dx + dy * dy
            if dist < minDistance {
                minDistance = dist
                closestIndex = index
            }
        }

        return closestIndex
    }
}
