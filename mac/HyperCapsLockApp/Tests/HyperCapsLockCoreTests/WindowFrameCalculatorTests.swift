import CoreGraphics
import Testing
@testable import HyperCapsLockCore

@Suite("WindowFrameCalculator Tests")
struct WindowFrameCalculatorTests {
    @Test("プライマリ画面（メニューバー・Dock差し引き後）の左右分割AX座標が正しい")
    func primaryScreenLeftAndRightSplit() {
        // 1440x900 画面で上25ptメニューバー、下65pt Dock の場合: visibleFrameCocoa = (0, 65, 1440, 810)
        // maxY = 875 -> axY = 900 - 875 = 25
        let visible = CGRect(x: 0, y: 65, width: 1440, height: 810)
        let left = WindowFrameCalculator.axFrame(for: visible, primaryScreenHeight: 900, side: .leftHalf)
        let right = WindowFrameCalculator.axFrame(for: visible, primaryScreenHeight: 900, side: .rightHalf)

        #expect(left == CGRect(x: 0, y: 25, width: 720, height: 810))
        #expect(right == CGRect(x: 720, y: 25, width: 720, height: 810))
    }

    @Test("奇数幅でも左右合計が画面幅とぴったり一致する")
    func oddWidthPreservesExactSum() {
        let visible = CGRect(x: 100, y: 0, width: 1001, height: 800)
        let left = WindowFrameCalculator.axFrame(for: visible, primaryScreenHeight: 800, side: .leftHalf)
        let right = WindowFrameCalculator.axFrame(for: visible, primaryScreenHeight: 800, side: .rightHalf)

        #expect(left.width == 500)
        #expect(right.width == 501)
        #expect(left.maxX == right.minX)
    }

    @Test("マルチディスプレイで重なり最大の画面を正しく選ぶ")
    func picksMostOverlappingScreen() {
        let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let secondaryRight = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let windowAX = CGRect(x: 1600, y: 100, width: 800, height: 600)

        let index = WindowFrameCalculator.bestMatchingScreenIndex(
            forAXWindowFrame: windowAX,
            screenFramesCocoa: [primary, secondaryRight],
            primaryScreenHeight: 900
        )
        #expect(index == 1)
    }
}
