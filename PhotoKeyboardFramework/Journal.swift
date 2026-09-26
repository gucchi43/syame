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
}
