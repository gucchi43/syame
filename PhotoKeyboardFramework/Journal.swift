//
//  Journal.swift
//  PhotoKeyboardFramework
//
//  ノートの紙・インク・テープの色と、手書きとタイプライターの書体。
//  方針は DESIGN.md と docs/superpowers/specs/2026-09-27-journal-notebook-design.md。
//

import UIKit

extension UIColor {
    fileprivate static func journalAdaptive(light: UInt32, lightAlpha: CGFloat = 1,
                                            dark: UInt32, darkAlpha: CGFloat = 1) -> UIColor {
        func make(_ hex: UInt32, _ alpha: CGFloat) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
        }
        return UIColor { $0.userInterfaceStyle == .dark ? make(dark, darkAlpha) : make(light, lightAlpha) }
    }

    /// 方眼の線
    public static let paperGrid = journalAdaptive(light: 0x788296, lightAlpha: 0.12, dark: 0xC8CDDC, darkAlpha: 0.12)
    /// 鉛筆。textSecondary と同じ色を、ノートの文脈で呼ぶための名前
    public static let pencil = UIColor.textSecondary
    /// 白いテープ(ライトでもダークでも白)
    public static let tapeWhite = journalAdaptive(light: 0xEDEAE2, dark: 0xEDEAE2)
    /// 透明なテープ
    public static let tapeClear = journalAdaptive(light: 0xFFFFFF, lightAlpha: 0.45, dark: 0xFFFFFF, darkAlpha: 0.22)
    /// 荷札・星のシール
    public static let kraft = journalAdaptive(light: 0xE9DFC6, dark: 0xCDBF9E)
    /// kraft の上の文字。kraft はライト・ダークどちらでも明るいので、文字は両モードとも濃い茶で固定
    public static let onKraft = journalAdaptive(light: 0x3A2E1E, dark: 0x3A2E1E)
}

extension UIFont {
    /// 手書き。題名・メモ・付箋・「次はここ」
    public static let journalFontName = "ZenKurenaido-Regular"
    /// タイプライター。ロゴ・日付・荷札
    public static let labelFontName = "SpecialElite-Regular"

    /// 手書きの書体を、文字サイズの設定に追従する大きさで返す。
    /// 読み込めないとき(キーボード拡張やテスト)は丸ゴシックに落とす
    public static func journal(_ style: UIFont.TextStyle) -> UIFont {
        let size = standardPointSize(for: style)
        guard let font = UIFont(name: journalFontName, size: size) else { return .brand(style) }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }

    /// タイプライターの書体。読み込めないときは Courier に落とす
    public static func label(_ style: UIFont.TextStyle) -> UIFont {
        let size = standardPointSize(for: style)
        let font = UIFont(name: labelFontName, size: size)
            ?? UIFont(name: "Courier", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }

    /// 標準の文字サイズ設定での大きさ。UIFontMetrics がここから利用者の設定へ拡大縮小する。
    /// preferredFont の大きさを渡すと、設定の倍率が二重に掛かる
    private static func standardPointSize(for style: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: style,
                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize
    }
}
