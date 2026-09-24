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

// MARK: - 膨らむ面

/// クレイ質感の面。外側の柔らかい影、上端の内側ハイライト、下端の内側の陰で膨らみを作る。
///
/// 外側の影を持つ層(self, clip なし)と、中身を丸く切る層(body, clip あり)の 2 層で組む。
/// 1 層で clipsToBounds を立てると外側の影が切れる。
/// 子ビューは contentView に載せる。
public final class ClaySurface: UIView {
    public enum Style {
        /// 膨らむ。ボタン、カード
        case raised
        /// くぼむ。空きスロット、入力欄
        case recessed
    }

    public let style: Style
    public var fill: UIColor { didSet { applyColors() } }
    public var cornerRadius: CGFloat { didSet { setNeedsLayout() } }

    /// 子ビューの置き場
    public let contentView = UIView()

    private let body = UIView()
    private let highlight = CAGradientLayer()
    private let shade = CAGradientLayer()

    public init(style: Style = .raised, fill: UIColor = .clayLavender, cornerRadius: CGFloat = Radius.card) {
        self.style = style
        self.fill = fill
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.style = .raised
        self.fill = .clayLavender
        self.cornerRadius = Radius.card
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        body.clipsToBounds = true
        body.layer.cornerCurve = .continuous
        body.translatesAutoresizingMaskIntoConstraints = false
        addSubview(body)

        // 上端の光と下端の陰。向きは style で決める
        highlight.startPoint = CGPoint(x: 0.5, y: 0)
        highlight.endPoint = CGPoint(x: 0.5, y: 1)
        shade.startPoint = CGPoint(x: 0.5, y: 1)
        shade.endPoint = CGPoint(x: 0.5, y: 0)
        body.layer.addSublayer(highlight)
        body.layer.addSublayer(shade)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        body.addSubview(contentView)

        // body と contentView を frame ではなく制約で面に貼る。
        // frame で置くと、子ビューを制約で contentView に載せたときに
        // intrinsic size が面へ伝わらず、幅が 0 に潰れる
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: topAnchor),
            body.bottomAnchor.constraint(equalTo: bottomAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor),
            body.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: body.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: body.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: body.trailingAnchor)
        ])

        layer.cornerCurve = .continuous
        applyColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        body.layer.cornerRadius = cornerRadius
        highlight.frame = body.bounds
        shade.frame = body.bounds
        // 影の形を先に決めておくと、レイアウトのたびに影を計算し直さない
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 影と cgColor は自動で明暗に追従しないため、ここで引き直す
        applyColors()
    }

    private func applyColors() {
        let resolvedFill = fill.resolvedColor(with: traitCollection)
        let light = UIColor.clayHighlight(of: fill).resolvedColor(with: traitCollection)
        let dark = UIColor.clayShade(of: fill).resolvedColor(with: traitCollection)
        body.backgroundColor = resolvedFill

        switch style {
        case .raised:
            // 上から光が当たり、下に陰が落ちる
            highlight.colors = [light.withAlphaComponent(0.9).cgColor, light.withAlphaComponent(0).cgColor]
            highlight.locations = [0, 0.45]
            shade.colors = [dark.withAlphaComponent(0.55).cgColor, dark.withAlphaComponent(0).cgColor]
            shade.locations = [0, 0.4]
            layer.shadowColor = dark.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 6)
            layer.shadowRadius = 12
            layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.55 : 0.35
        case .recessed:
            // 上から陰が落ち、下端がわずかに光る。外側の影は持たない
            highlight.colors = [dark.withAlphaComponent(0.6).cgColor, dark.withAlphaComponent(0).cgColor]
            highlight.locations = [0, 0.4]
            shade.colors = [light.withAlphaComponent(0.7).cgColor, light.withAlphaComponent(0).cgColor]
            shade.locations = [0, 0.35]
            layer.shadowOpacity = 0
        }
    }
}

// MARK: - 押すと沈むボタン

/// クレイの面を土台にしたボタン。押すと沈み、離すとバネで戻り、押した瞬間に振動する。
///
/// UIButton の派生にしているのは、Storyboard の customClass と
/// `@IBOutlet weak var button: UIButton!` からそのまま使うため。
/// 面は subview として最背面に置き、UIButton の title / image はその上に載る。
public class ClayButton: UIButton {
    private let surface = ClaySurface(style: .raised, fill: .clayLavender, cornerRadius: Radius.small)

    /// 面の色
    public var fill: UIColor {
        get { surface.fill }
        set { surface.fill = newValue }
    }

    /// 面の角丸。真円にしたいときは layoutSubviews で高さの半分を入れる
    public var cornerRadius: CGFloat {
        get { surface.cornerRadius }
        set { surface.cornerRadius = newValue }
    }

    /// 真円にする。round(symbol:) が立てる
    private var isCircular = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        surface.isUserInteractionEnabled = false
        insertSubview(surface, at: 0)
        // 沈む動きだけで押下を伝える。UIKit の自動の暗転は重ねない
        adjustsImageWhenHighlighted = false

        setTitleColor(.textPrimary, for: .normal)
        // 無効の見た目は isEnabled の didSet が付ける alpha 0.6 だけに任せる。
        // ここでも文字色を薄めると二重に薄まって文字が読めなくなる
        tintColor = .textPrimary
        // CTA は太字。細いままだと淡い面の上で線が痩せる
        titleLabel?.font = .scaled(.body, weight: .bold)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        surface.frame = bounds
        if isCircular {
            surface.cornerRadius = bounds.height / 2
        }
        // UIButton は setImage 等のタイミングによって内部の imageView / titleLabel を
        // surface より背面に置き直すことがある。レイアウトのたびに前面へ出し直す
        imageView.map { bringSubviewToFront($0) }
        titleLabel.map { bringSubviewToFront($0) }
    }

    public override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            if isHighlighted {
                Haptic.play(.tap)
                Motion.pressDown(self)
            } else {
                Motion.release(self)
            }
        }
    }

    public override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1.0 : 0.6 }
    }

    /// アイコンだけの丸いボタン。キーボードのツールバーや閉じるボタンに使う。44pt 以上
    public static func round(symbol: String, size: CGFloat = 44, fill: UIColor = .clayLavender) -> ClayButton {
        let button = ClayButton(frame: CGRect(x: 0, y: 0, width: size, height: size))
        button.isCircular = true
        button.fill = fill
        button.setImage(.symbol(symbol, textStyle: .body, weight: .semibold), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return button
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
