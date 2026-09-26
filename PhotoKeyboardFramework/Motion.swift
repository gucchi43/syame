//
//  Motion.swift
//  PhotoKeyboardFramework
//
//  押す・貼るの動きと振動。時間とバネはここでだけ決める。
//  「視差効果を減らす」が有効なら、移動と回転をせずフェードだけにする。
//  メインスレッドからだけ呼ぶ。
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

    /// ビュー自身に紐付けた押す前の姿勢を取り出す。ない場合は nil
    private static func restingTransform(for view: UIView) -> CGAffineTransform? {
        let value = objc_getAssociatedObject(view, &restingKey) as? NSValue
        return value?.cgAffineTransformValue
    }

    /// ビュー自身に押す前の姿勢を紐付ける
    private static func setRestingTransform(_ transform: CGAffineTransform, for view: UIView) {
        objc_setAssociatedObject(view, &restingKey, NSValue(cgAffineTransform: transform), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// ビュー自身に紐付けた押す前の姿勢を消す
    private static func clearRestingTransform(for view: UIView) {
        objc_setAssociatedObject(view, &restingKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static var restingKey: UInt8 = 0

    /// 押した瞬間。いまの姿勢(回転を含む)に縮みを掛け合わせる
    public static func pressDown(_ view: UIView) {
        guard !isReduced else { return }
        let resting = view.transform
        setRestingTransform(resting, for: view)
        UIView.animate(withDuration: pressDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = resting.scaledBy(x: pressScale, y: pressScale)
        }
    }

    /// 離した瞬間。押す前の姿勢へバネで戻す。押していなければ何もしない
    public static func release(_ view: UIView) {
        guard !isReduced else { return }
        guard let resting = restingTransform(for: view) else { return }
        clearRestingTransform(for: view)
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
