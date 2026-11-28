import SwiftUI

/// アプリの色は正式アイコンから採る（docs/app-theme.md が正本）。
/// 役割: teal = 主役（操作・実行中）、orange = 注意と相棒の差し色、
/// yellow = キーキャップの強調（CAPS の文字色）、navy / key = キーの地色。
enum AppTheme {
    /// アイコンの背景の濃紺
    static let navy = Color(red: 20.0 / 255, green: 30.0 / 255, blue: 68.0 / 255)
    /// キーキャップの黒
    static let key = Color(red: 35.0 / 255, green: 35.0 / 255, blue: 41.0 / 255)
    /// 計器盤のティール。文字や操作に使うため、アイコンの色より少し深くしてある
    static let teal = Color(red: 10.0 / 255, green: 128.0 / 255, blue: 122.0 / 255)
    /// 相棒の LED のミント
    static let led = Color(red: 46.0 / 255, green: 230.0 / 255, blue: 184.0 / 255)
    /// ヘッドセットと計器のオレンジ
    static let orange = Color(red: 245.0 / 255, green: 125.0 / 255, blue: 30.0 / 255)
    /// CAPS の黄色
    static let yellow = Color(red: 255.0 / 255, green: 214.0 / 255, blue: 10.0 / 255)
    /// コックピット窓の淡色
    static let pale = Color(red: 217.0 / 255, green: 236.0 / 255, blue: 235.0 / 255)
}

/// アイコンのキーキャップを模した小さなマーク。ヘッダーで使う。
struct KeyMarkView: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(AppTheme.key)
            RoundedRectangle(cornerRadius: size * 0.26)
                .strokeBorder(AppTheme.navy.opacity(0.6), lineWidth: 1)
            Text("⇪")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(AppTheme.yellow)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// セクションカードの面。淡い窓色の代わりに、明暗どちらの外観でも
/// 文字のコントラストが保てるよう、地は primary の薄い色にして、
/// 輪郭だけ計器盤のティールで引く。
struct CockpitCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AppTheme.teal.opacity(0.28), lineWidth: 1)
            )
    }
}

extension View {
    func cockpitCardSurface() -> some View {
        modifier(CockpitCardSurface())
    }
}
