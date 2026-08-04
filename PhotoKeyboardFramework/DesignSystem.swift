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
    public static let bgBase = adaptive(light: 0xF5F5F5, dark: 0x131314)

    /// カード・セル・モーダルの面。地との差はごくわずかにする。
    /// 文字は高コントラスト、面は極低コントラストという二極構造が「軽さ」を作る。
    public static let bgSurface = adaptive(light: 0xFFFFFF, dark: 0x1E1E20)

    /// 本文・見出し。地に対して16:1以上あり、淡い見た目でも可読性は落とさない。
    public static let textPrimary = adaptive(light: 0x191919, dark: 0xF2F2F2)

    /// 補足・メタ情報。地に対して4.89:1で、本文基準の4.5:1を満たす。
    public static let textSecondary = adaptive(light: 0x6B6B6B, dark: 0x9B9B9B)

    /// アクセント。塗りと選択状態にのみ使い、地や本文には使わない。
    /// 白地で4.55:1、黒地で8.42:1。将来ユーザーが選べるテーマカラーに置き換える。
    public static let brandAccent = adaptive(light: 0x00875A, dark: 0x30D158)

    /// アクセントで塗った面の上に載せる文字色。
    /// ダークでは明るい緑になるため、白ではなく暗い色を載せる。
    public static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x1C1C1E)

    /// 区切り線
    public static let separatorLine = adaptive(light: 0xE2E2E4, dark: 0x2E2E31)
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
    public static let help = "questionmark.circle"
    public static let sortByName = "textformat.abc"
    public static let sortByPopularity = "arrow.up.arrow.down"
    public static let close = "xmark"
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
    public func applySymbol(_ name: String, textStyle: UIFont.TextStyle = .body, tint: UIColor = .brandAccent) {
        setTitle(nil, for: .normal)
        setImage(.symbol(name, textStyle: textStyle), for: .normal)
        tintColor = tint
    }
}

extension UIBarButtonItem {
    /// バーボタンをアイコン表示にする
    public func applySymbol(_ name: String, tint: UIColor = .brandAccent) {
        title = nil
        image = .symbol(name)
        tintColor = tint
    }
}
