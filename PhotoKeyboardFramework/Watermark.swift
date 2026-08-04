//
//  Watermark.swift
//  PhotoKeyboardFramework
//
//  コピーする画像へのロゴ焼き込み。
//  本体アプリとキーボード拡張のどちらから貼っても同じ結果になるよう、処理をここに集約する。
//

import UIKit

public enum Watermark {

    /// 焼き込みを行うかどうか。
    ///
    /// 現在は false。アプリ名とロゴの変更を予定しており、
    /// これから捨てるブランドをユーザーの画像に刻んでも意味がないため。
    ///
    /// 新しいロゴが決まったら、次の順序で有効化する。
    /// 1. `logoImageName` の素材を差し替える
    /// 2. 実機でチャットに貼り、その表示サイズでロゴが読めるかを確認する
    ///    (読めないなら、体験を損なうだけで宣伝効果はゼロになる)
    /// 3. 無料プランのみ true、課金ユーザーは false にする
    public static var isEnabled = false

    /// 焼き込むロゴ。Framework のバンドルに置いているため、
    /// 本体アプリとキーボード拡張の両方から同じ素材を参照できる。
    private static let logoImageName = "photo_logo_2"

    /// 元画像に対するロゴの縮小率。1.0 は素材の実寸
    private static let scale: CGFloat = 1.0

    private static var logo: UIImage? {
        return UIImage(named: logoImageName,
                       in: Bundle(for: RealmPhoto.self),
                       compatibleWith: nil)
    }

    /// ロゴを焼き込んだ画像を返す。
    /// 無効時や素材が読めないときは元画像をそのまま返すため、呼び出し側で分岐は不要。
    public static func applied(to image: UIImage) -> UIImage {
        guard isEnabled, let logo = logo else { return image }
        return image.composite(image: logo, rate: scale) ?? image
    }
}

extension UIImage {
    /// ロゴを焼き込んだうえでクリップボードへ置く。
    /// コピーの経路をこの1本にまとめ、貼り付け結果が経路によって変わらないようにする。
    public func copyToPasteboardWithWatermark() {
        Watermark.applied(to: self).copyToGeneralPasteboard()
    }
}
