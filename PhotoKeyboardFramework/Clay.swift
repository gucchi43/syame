//
//  Clay.swift
//  PhotoKeyboardFramework
//
//  クレイ質感の部品。面の色、膨らむ面(ClaySurface)、押すと沈むボタン(ClayButton)、
//  動き(Motion)、振動(Haptic)をここに集める。影とグラデーションを描くのはこのファイルだけ。
//  方針と根拠は DESIGN.md と docs/superpowers/specs/2026-09-24-clay-game-ui-design.md を参照。
//

import UIKit

// MARK: - 面の色

extension UIColor {
    fileprivate convenience init(clayHex hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(hex & 0xFF) / 255.0,
                  alpha: 1.0)
    }

    fileprivate static func clayAdaptive(light: UInt32, dark: UInt32) -> UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(clayHex: dark) : UIColor(clayHex: light)
        }
    }

    /// 既定の面。藤色系。ボタン、カード
    public static let clayLavender = clayAdaptive(light: 0xD9D0F2, dark: 0x3A3352)
    /// 進み具合のピル、完成の表示
    public static let clayMint = clayAdaptive(light: 0xCDEBDD, dark: 0x27423A)
    /// 空きスロットの「+」、注意喚起
    public static let clayPeach = clayAdaptive(light: 0xF8D9CC, dark: 0x4A342E)
    /// 案内行、補助のバッジ
    public static let claySky = clayAdaptive(light: 0xCFE3F5, dark: 0x2A3A4E)

    /// 面の色を白の方へ寄せる。ダークでは面が暗いぶん寄せ幅を抑え、白飛びを避ける
    public static func clayHighlight(of base: UIColor) -> UIColor {
        return UIColor { traits in
            let amount: CGFloat = traits.userInterfaceStyle == .dark ? 0.20 : 0.35
            return base.resolvedColor(with: traits).clayMixed(with: .white, amount: amount)
        }
    }

    /// 面の色を黒の方へ寄せる。影と下端の陰に使う
    public static func clayShade(of base: UIColor) -> UIColor {
        return UIColor { traits in
            let amount: CGFloat = traits.userInterfaceStyle == .dark ? 0.35 : 0.18
            return base.resolvedColor(with: traits).clayMixed(with: .black, amount: amount)
        }
    }

    /// 2 色を RGB で線形に混ぜる。amount が 1 なら other になる
    fileprivate func clayMixed(with other: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = min(max(amount, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t,
                       alpha: a1)
    }
}
