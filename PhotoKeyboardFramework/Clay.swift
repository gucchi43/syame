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

// MARK: - 動き

/// 押下・出現・完成の動き。時間とバネはここでだけ決める。
/// 「視差効果を減らす」が有効なら縮小と移動を行わず、フェードだけにする。
public enum Motion {
    /// テストから設定を固定するための上書き。nil なら端末の設定に従う
    public static var isReducedOverride: Bool?

    public static var isReduced: Bool {
        return isReducedOverride ?? UIAccessibility.isReduceMotionEnabled
    }

    /// 沈む速さ。指の動きより遅いと重く感じる
    public static let pressDuration: TimeInterval = 0.12
    /// 戻りのバネ。小さいほど大きく揺れる
    public static let pressDamping: CGFloat = 0.55
    /// 沈んだときの縮み
    public static let pressScale: CGFloat = 0.96
    /// 沈んだときの下がり
    public static let pressDrop: CGFloat = 2

    /// 出現の時間とバネ
    public static let popDuration: TimeInterval = 0.45
    public static let popDamping: CGFloat = 0.6
    /// 完成の波で、隣のマスをずらす間隔
    public static let rippleStagger: TimeInterval = 0.05

    /// 押した瞬間。縮めて少し下げる
    public static func pressDown(_ view: UIView) {
        guard !isReduced else { return }
        UIView.animate(withDuration: pressDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = CGAffineTransform(scaleX: pressScale, y: pressScale)
                .translatedBy(x: 0, y: pressDrop)
        }
    }

    /// 離した瞬間。バネで元に戻す
    public static func release(_ view: UIView) {
        guard !isReduced else { return }
        // テストではアニメーションの終端を待たずに検証するため、最終値を先に置く
        UIView.animate(withDuration: pressDuration * 3, delay: 0,
                       usingSpringWithDamping: pressDamping, initialSpringVelocity: 0.5,
                       options: [.allowUserInteraction]) {
            view.transform = .identity
        }
        view.transform = .identity
    }

    /// 出現。0.6 倍から 1.05 倍を経て 1.0 へ。
    /// 縮小を使えない設定のときはフェードだけにする
    public static func pop(_ view: UIView, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        if isReduced {
            view.alpha = 0
            UIView.animate(withDuration: popDuration * 0.5, delay: delay, options: []) {
                view.alpha = 1
            } completion: { _ in completion?() }
            return
        }
        view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        view.alpha = 0
        UIView.animate(withDuration: popDuration * 0.4, delay: delay, options: [.curveEaseOut]) {
            view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            view.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: popDuration * 0.6, delay: 0,
                           usingSpringWithDamping: popDamping, initialSpringVelocity: 0.3,
                           options: []) {
                view.transform = .identity
            } completion: { _ in completion?() }
        }
    }
}

// MARK: - 振動

/// 振動の生成器。テストでは記録用に差し替える
public protocol HapticDriver {
    func play(_ kind: Haptic.Kind)
}

/// 端末の生成器で鳴らす既定の実装
final class SystemHapticDriver: HapticDriver {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func play(_ kind: Haptic.Kind) {
        switch kind {
        case .tap: light.impactOccurred()
        case .fill: medium.impactOccurred()
        case .complete: notification.notificationOccurred(.success)
        }
    }
}

/// 振動の種類。音は入れない(spec)
public enum Haptic {
    public enum Kind: Equatable {
        /// ボタンを押した
        case tap
        /// マスが埋まった
        case fill
        /// 上限まで埋まった
        case complete
    }

    public static var driver: HapticDriver = SystemHapticDriver()

    public static func play(_ kind: Kind) {
        driver.play(kind)
    }
}
