//
//  DesignSystem.swift
//  PhotoKeyboardFramework
//
//  デザイントークンの一元管理。本体アプリとキーボード拡張の両方から参照する。
//  方針と根拠は DESIGN.md を参照。
//

import UIKit

// MARK: - 余白

/// 4pt を基本単位とし、使う値を限定する。中間値を作らない。
public enum Spacing {
    /// グリッドのセル間。参照アプリの実測値(setlogは約2pt)に合わせて詰める
    public static let grid: CGFloat = 2
    /// 密接した要素間
    public static let s: CGFloat = 8
    /// カード内部の余白
    public static let m: CGFloat = 12
    /// 画面の左右マージン
    public static let l: CGFloat = 16
    /// セクション間
    public static let xl: CGFloat = 24
}

// MARK: - 角丸

/// 「ピル」と「中程度」の2種類だけを使う。中途半端な角丸と直角を作らない。
public enum Radius {
    /// 入力欄、小さいカード
    public static let small: CGFloat = 12
    /// 画像セル、カード。参照アプリの実測値(setlogは約20pt)に近づける
    public static let card: CGFloat = 16
}

extension UIView {
    /// iOS 実機と同じスムーズな角丸を適用する。
    /// cornerCurve を指定しないと単純な円弧になり、ネイティブに見えない。
    public func applyCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    /// 高さの半分で丸める。ボタン・タグ・セグメントはこれを使う。
    public func applyPillShape() {
        applyCornerRadius(bounds.height / 2)
    }
}

// MARK: - 配色

extension UIColor {
    /// 16進文字列から生成する。DesignSystem を外部ライブラリに依存させないための最小実装。
    fileprivate convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    fileprivate static func adaptive(light: UInt32, dark: UInt32) -> UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }

    /// 紙。方眼ノートの地。ダークでは黒い紙
    public static let bgBase = adaptive(light: 0xF8F7F2, dark: 0x1B1A1E)

    /// ポラロイドの枠やメモの下地。紙より一段明るい(ダークでは一段明るい黒)
    public static let bgSurface = adaptive(light: 0xFFFEFB, dark: 0x242328)

    /// ペン
    public static let textPrimary = adaptive(light: 0x1E1C1A, dark: 0xEFEBE3)

    /// 鉛筆。補足と「次はここ」。紙に対して 4.5:1 を保つ濃さ
    public static let textSecondary = adaptive(light: 0x6E695F, dark: 0x9A958B)

    /// テープ。ライトは黒、ダークは白
    public static let accent = adaptive(light: 0x1C1B19, dark: 0xEDEAE2)

    /// テープの上の文字
    public static let onAccent = adaptive(light: 0xF8F7F2, dark: 0x1B1A1E)

    /// 付箋
    public static let accentSoft = adaptive(light: 0xF6E7A1, dark: 0x5A5230)

    /// キーボードの地。純正キーボードの色に寄せる。
    /// アプリの地(bgBase)をそのまま使うと、白いパネルが乗っているように見えて浮く。
    public static let keyboardBase = adaptive(light: 0xD1D3D9, dark: 0x2C2C2E)

    /// キーボード上のセル・キーの面。地より1段明るくする
    public static let keyboardSurface = adaptive(light: 0xFFFFFF, dark: 0x4A4A4F)

    /// 区切り線
    public static let separatorLine = adaptive(light: 0xE4E2EC, dark: 0x2F2D38)

    /// オーロラの面に載せる文字・アイコンの色。
    ///
    /// 淡いオーロラの上では白の比が最も明るい帯で 1.3:1 しかなく、色だけでは読めない。
    /// そのため白は必ず onAuroraShadow と組で使い、影で輪郭を作る(applyAuroraText)。
    /// 明暗で変えないのは、下地のグラデーションが両モードで同じだから。
    public static let onAurora = adaptive(light: 0xFFFFFF, dark: 0xFFFFFF)

    /// 白い文字を淡い地から浮かせるための影。
    /// 濃くすると縁が黒くにじんで見えるため、輪郭がわずかに立つ程度に留める。
    public static let onAuroraShadow = UIColor(hex: 0x1A1922).withAlphaComponent(0.3)
}

// MARK: - オーロラ

/// アイコンのホログラムシールと同じ虹。CTAとトーストに使う。
///
/// アイコンと同じ淡さをそのまま使っている。地(bgBase)との明度差は小さいので、
/// ボタンは色そのものではなく、虹が動くことと角丸の形で認識させる。
/// 文字は白ではなく onAurora(濃い色)を置くこと。
///
/// 端を同じ銀に戻してあるため、どの角度で切っても金属の連続に見える。
/// 色と順序はアイコンの生成器(tools/make_icon.swift)と揃えること。
public enum Aurora {
    public static let colors: [UIColor] = [
        UIColor(hex: 0xD7DEE8), UIColor(hex: 0xB9C8E8), UIColor(hex: 0xCFC0EC), UIColor(hex: 0xF0C6DE),
        UIColor(hex: 0xF6DCC0), UIColor(hex: 0xDCEBC6), UIColor(hex: 0xC2E4E4), UIColor(hex: 0xD7DEE8),
    ]
    public static let locations: [NSNumber] = [0.0, 0.12, 0.26, 0.40, 0.54, 0.67, 0.80, 1.0]

    /// 斜めに流す。水平だと帯が平行線に見えて金属らしさが出ない
    public static let start = CGPoint(x: 0.0, y: 0.15)
    public static let end = CGPoint(x: 1.0, y: 0.85)

    public static func apply(to layer: CAGradientLayer) {
        layer.colors = colors.map { $0.cgColor }
        layer.locations = locations
        layer.startPoint = start
        layer.endPoint = end
    }
}

/// 自前で塗るのではなく layer そのものをグラデーションにする。
///
/// CAGradientLayer をサブレイヤーとして足す方法だと、ビューの大きさが変わるたびに
/// frame を追従させる必要があり、更新漏れで帯がずれる。layerClass を置き換えれば
/// レイアウトに自動で追従する。
public class AuroraView: UIView {
    public override class var layerClass: AnyClass { CAGradientLayer.self }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        Aurora.apply(to: layer as! CAGradientLayer)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        Aurora.apply(to: layer as! CAGradientLayer)
    }
}

extension AuroraView {
    /// オーロラで塗ったトーストを作る。
    ///
    /// Toast の ToastStyle は単色しか持てないため、塗りたい場合はビューごと渡す。
    /// showToast(_ view:) は大きさを決めてくれないので、ここで確定させておく。
    public static func makeToast(message: String, maxWidth: CGFloat) -> UIView {
        let container = AuroraView()
        container.applyCornerRadius(Radius.small)

        let label = UILabel()
        label.text = message
        label.applyAuroraText()
        label.font = .scaled(.subheadline, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: Spacing.m),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Spacing.m),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Spacing.xl),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Spacing.xl)
        ])

        let fitting = container.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel)
        container.frame = CGRect(x: 0, y: 0,
                                 width: min(fitting.width, maxWidth),
                                 height: fitting.height)
        return container
    }
}

/// オーロラで塗るボタン。Storyboard 側でクラスをこれに変えて使う
public class AuroraButton: UIButton {
    public override class var layerClass: AnyClass { CAGradientLayer.self }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Aurora.apply(to: layer as! CAGradientLayer)
        setTitleColor(.onAurora, for: .normal)
        tintColor = .onAurora
        titleLabel?.applyAuroraText()
        // CTAは太字。細いままだと淡い地の上で線が痩せて読みにくい
        titleLabel?.font = .scaled(.body, weight: .bold)
        titleLabel?.adjustsFontForContentSizeCategory = true
        // アイコンだけのボタン(FAB)は影が付かないので、レイヤー側にも同じ影を落とす
        imageView?.layer.shadowColor = UIColor.onAuroraShadow.cgColor
        imageView?.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView?.layer.shadowOpacity = 1
        imageView?.layer.shadowRadius = 2
    }
}

// MARK: - タイポグラフィ

extension UIFont {
    /// Dynamic Type に追従するフォントを返す。
    /// サイズのメリハリは小さく保ち、階層は太さで作る(DESIGN.md)。
    public static func scaled(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let descriptor = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }
}

extension UIFont {
    /// ブランド名を出すための書体。
    ///
    /// 丸ゴシック系の太字で、角の立った本文書体との差で名前が名前として立つ。
    /// SF Pro Rounded は OS に入っているため同梱もライセンス確認も要らない。
    /// 将来ロゴタイプを起こしたら、この関数ではなくベクタ画像に差し替える
    /// (MainTabViewController の titleView を置き換えるだけで済むようにしてある)。
    public static func brand(_ style: UIFont.TextStyle = .title3) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let heavy = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy]
        ])
        // 丸ゴシックが使えない環境では太さだけ効かせる
        guard let rounded = heavy.withDesign(.rounded) else {
            return UIFont(descriptor: heavy, size: base.pointSize)
        }
        return UIFont(descriptor: rounded, size: base.pointSize)
    }
}

extension UILabel {
    /// オーロラの上に置く文字の設定。
    ///
    /// 白のままだと淡い帯に沈むため、濃い影を薄く敷いて輪郭を作る。
    /// 影は装飾ではなく可読性のための措置なので、白を使うなら必ず一緒に付けること。
    public func applyAuroraText() {
        textColor = .onAurora
        shadowColor = .onAuroraShadow
        shadowOffset = CGSize(width: 0, height: 1)
    }

    /// テキストスタイルを適用し、文字サイズ設定への追従を有効にする。
    public func applyTextStyle(_ style: UIFont.TextStyle,
                               weight: UIFont.Weight = .regular,
                               color: UIColor = .textPrimary) {
        font = .scaled(style, weight: weight)
        adjustsFontForContentSizeCategory = true
        textColor = color
    }
}

// MARK: - アイコン

/// 使用する SF Symbols の名前。FontAwesome から移行した13種。
/// 文字列直書きを避け、typo によるアイコン欠落を防ぐ。
public enum Symbol {
    public static let menu = "line.3.horizontal"
    public static let more = "ellipsis"
    public static let textMode = "textformat"
    public static let globe = "globe"
    public static let emptyState = "face.smiling"
    public static let home = "house"
    public static let imageMode = "photo.on.rectangle"
    public static let add = "plus"
    /// 列数の切り替え。粗い方(3列)と細かい方(5列)
    public static let gridSparse = "square.grid.2x2"
    public static let gridDense = "square.grid.3x3"
    public static let close = "xmark"
    public static let copy = "doc.on.doc"
    public static let delete = "trash"
    /// 送り方の案内(HowToSendViewController)の3ステップ
    public static let stepTap = "hand.tap"
    public static let stepClipboard = "doc.on.clipboard"
    public static let stepSend = "paperplane"
    /// 次の手順へ進めることを示す(オンボーディングの案内行)
    public static let next = "chevron.right"
}

extension UIImage {
    /// テキストスタイル基準で SF Symbol を作る。
    /// pt 指定にすると文字サイズ設定に追従しない。
    public static func symbol(_ name: String,
                              textStyle: UIFont.TextStyle = .body,
                              weight: UIImage.SymbolWeight = .regular) -> UIImage? {
        let config = UIImage.SymbolConfiguration(textStyle: textStyle)
            .applying(UIImage.SymbolConfiguration(weight: weight))
        return UIImage(systemName: name, withConfiguration: config)
    }

    /// 空状態などで使う、大きさを直接指定する版
    public static func symbol(_ name: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .regular) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return UIImage(systemName: name, withConfiguration: config)
    }
}

extension UIButton {
    /// アイコンボタンとして設定する。文字ベースのアイコンを置き換えるための共通処理。
    public func applySymbol(_ name: String, textStyle: UIFont.TextStyle = .body, tint: UIColor = .accent) {
        setTitle(nil, for: .normal)
        setImage(.symbol(name, textStyle: textStyle), for: .normal)
        tintColor = tint
    }
}

extension UIBarButtonItem {
    /// バーボタンをアイコン表示にする
    public func applySymbol(_ name: String, tint: UIColor = .accent) {
        title = nil
        image = .symbol(name)
        tintColor = tint
    }
}
