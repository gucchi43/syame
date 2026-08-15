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

    /// 画面の地。
    /// 参照した5アプリ(setlog #F4F5F5 / relight #F5F5F5 / 推しスケ #F6F6F6 ほか)は
    /// いずれも純白を地に使っていない。
    /// 完全な無彩色ではなくアクセントの藤色へわずかに寄せてあり、灰色が「選ばれた灰色」に見える。
    public static let bgBase = adaptive(light: 0xF5F4F8, dark: 0x141318)

    /// カード・セル・モーダルの面。地との差はごくわずかにする。
    /// 文字は高コントラスト、面は極低コントラストという二極構造が「軽さ」を作る。
    public static let bgSurface = adaptive(light: 0xFFFFFF, dark: 0x1F1E24)

    /// 本文・見出し。地に対して15:1以上あり、淡い見た目でも可読性は落とさない。
    public static let textPrimary = adaptive(light: 0x1A1922, dark: 0xF2F1F5)

    /// 補足・メタ情報。地に対して5.11:1で、本文基準の4.5:1を満たす。
    public static let textSecondary = adaptive(light: 0x6A6775, dark: 0x9B98A6)

    /// 操作要素の色。塗りボタンや選択状態に使い、地や本文には使わない。
    ///
    /// アイコンのホログラムシールを敷く藤色から起こしたテーマカラー。
    /// 藤色そのものは淡すぎて白文字が乗らないため、色相を保ったまま明度を落とし、
    /// onAccent との比が 5.2:1 になる位置で止めている。
    public static let accent = adaptive(light: 0x7362AE, dark: 0xB9AEE8)

    /// accent で塗った面の上に載せる文字・アイコンの色
    public static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x1C1B22)

    /// 選択状態やタグの下地に使う、accent を薄めた面。
    /// accent をそのまま広い面に塗ると、並んだ画像より器が目立ってしまう。
    public static let accentSoft = adaptive(light: 0xECE9F7, dark: 0x2A2540)

    /// キーボードの地。純正キーボードの色に寄せる。
    /// アプリの地(bgBase)をそのまま使うと、白いパネルが乗っているように見えて浮く。
    public static let keyboardBase = adaptive(light: 0xD1D3D9, dark: 0x2C2C2E)

    /// キーボード上のセル・キーの面。地より1段明るくする
    public static let keyboardSurface = adaptive(light: 0xFFFFFF, dark: 0x4A4A4F)

    /// 区切り線
    public static let separatorLine = adaptive(light: 0xE4E2EC, dark: 0x2F2D38)
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
    public static let saveCount = "arrow.down.circle"
    public static let more = "ellipsis"
    public static let textMode = "textformat"
    public static let globe = "globe"
    public static let emptyState = "face.smiling"
    public static let home = "house"
    public static let imageMode = "photo.on.rectangle"
    public static let add = "plus"
    public static let sortByName = "textformat.abc"
    public static let sortByPopularity = "arrow.up.arrow.down"
    public static let close = "xmark"
    public static let copy = "doc.on.doc"
    public static let delete = "trash"
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
