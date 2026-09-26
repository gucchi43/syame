//
//  Motion.swift
//  PhotoKeyboardFramework
//
//  押す・貼るの動きと振動。時間とバネはここでだけ決める。
//  「視差効果を減らす」が有効なら、移動と回転をせずフェードだけにする。
//

import UIKit

public enum Motion {
    /// テストから設定を固定するための上書き。nil なら端末の設定に従う
    public static var isReducedOverride: Bool?

    public static var isReduced: Bool {
        return isReducedOverride ?? UIAccessibility.isReduceMotionEnabled
    }

    static let pressDuration: TimeInterval = 0.12
    static let pressScale: CGFloat = 0.96
    static let pasteDrop: CGFloat = 40
    static let pasteSpin: CGFloat = 0.14
    static let pasteDuration: TimeInterval = 0.55

    /// 押している間の姿勢。押す前の姿勢を覚えておき、離したらそこへ戻す
    private static var restingTransforms: [ObjectIdentifier: CGAffineTransform] = [:]

    /// 押した瞬間。いまの姿勢(回転を含む)に縮みを掛け合わせる
    public static func pressDown(_ view: UIView) {
        guard !isReduced else { return }
        let resting = view.transform
        restingTransforms[ObjectIdentifier(view)] = resting
        UIView.animate(withDuration: pressDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = resting.scaledBy(x: pressScale, y: pressScale)
        }
    }

    /// 離した瞬間。押す前の姿勢へバネで戻す
    public static func release(_ view: UIView) {
        guard !isReduced else { return }
        let resting = restingTransforms.removeValue(forKey: ObjectIdentifier(view)) ?? .identity
        UIView.animate(withDuration: pressDuration * 3, delay: 0, usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            view.transform = resting
        }
    }

    /// 貼る。テープごと上から落ちてきて、少し回りながら所定の姿勢で止まる
    public static func paste(_ view: UIView, to final: CGAffineTransform, completion: (() -> Void)?) {
        if isReduced {
            view.transform = final
            view.alpha = 0
            UIView.animate(withDuration: 0.25, animations: { view.alpha = 1 }) { _ in completion?() }
            return
        }
        view.alpha = 0
        view.transform = final.translatedBy(x: 0, y: -pasteDrop).rotated(by: pasteSpin)
        UIView.animate(withDuration: pasteDuration, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.2, options: [.curveEaseOut]) {
            view.transform = final
            view.alpha = 1
        } completion: { _ in completion?() }
    }
}

/// 振動の生成器。テストでは記録用に差し替える
public protocol HapticDriver {
    func play(_ kind: Haptic.Kind)
}

final class SystemHapticDriver: HapticDriver {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func play(_ kind: Haptic.Kind) {
        switch kind {
        case .tap: light.impactOccurred()
        case .paste: medium.impactOccurred()
        case .full: notification.notificationOccurred(.success)
        }
    }
}

/// 振動の種類。音は入れない
public enum Haptic {
    public enum Kind: Equatable {
        /// 押した
        case tap
        /// 写真を貼った
        case paste
        /// ノートがいっぱいになった
        case full
    }

    public static var driver: HapticDriver = SystemHapticDriver()

    public static func play(_ kind: Kind) {
        driver.play(kind)
    }
}
