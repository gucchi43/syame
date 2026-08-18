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
    /// 課金階層を入れたら、課金ユーザーだけ false にする。
    public static var isEnabled = true

    /// 焼き込むロゴ。Framework のバンドルに置いているため、
    /// 本体アプリとキーボード拡張の両方から同じ素材を参照できる。
    private static let logoImageName = "periperi_watermark"

    /// 元画像の幅に対するロゴの幅。
    /// 素材の実寸で焼くと、大きい画像では小さすぎ、小さい画像では画面を覆う。
    private static let widthRatio: CGFloat = 0.20

    /// 短辺に対する余白。角にぴったり付けると切り取られたように見える
    private static let marginRatio: CGFloat = 0.035

    /// 透かしの濃さ。濃いと元の画像を邪魔し、薄いと何も読めない
    private static let alpha: CGFloat = 0.6

    /// この幅を下回るなら焼かない。
    /// 潰れて読めないロゴは、宣伝にならないうえ画像を汚すだけになる。
    private static let minimumLogoWidth: CGFloat = 80

    private static var logo: UIImage? {
        return UIImage(named: logoImageName,
                       in: Bundle(for: RealmPhoto.self),
                       compatibleWith: nil)
    }

    /// ロゴを右下に焼き込んだ画像を返す。
    /// 無効時・素材が読めないとき・小さすぎて読めないときは元画像をそのまま返すため、
    /// 呼び出し側で分岐は不要。
    public static func applied(to image: UIImage) -> UIImage {
        guard isEnabled, let logo = logo,
              image.size.width > 0, image.size.height > 0, logo.size.width > 0 else {
            return image
        }
        let logoWidth = image.size.width * widthRatio
        guard logoWidth >= minimumLogoWidth else { return image }

        let logoHeight = logoWidth * (logo.size.height / logo.size.width)
        let margin = min(image.size.width, image.size.height) * marginRatio
        let rect = CGRect(x: image.size.width - logoWidth - margin,
                          y: image.size.height - logoHeight - margin,
                          width: logoWidth,
                          height: logoHeight)

        // scale に 0(デバイススケール)を渡すと 3x 端末で 9 倍のピクセル数になり、
        // メモリ上限の厳しいキーボード拡張が落ちる。1.0 で固定する。
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))

        // 白い被写体の上でロゴが消えないよう、ごく薄い影で輪郭を作る
        UIGraphicsGetCurrentContext()?.setShadow(
            offset: CGSize(width: 0, height: logoHeight * 0.05),
            blur: logoHeight * 0.15,
            color: UIColor.black.withAlphaComponent(0.35).cgColor)
        logo.draw(in: rect, blendMode: .normal, alpha: alpha)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

extension UIImage {
    /// ロゴを焼き込んだうえでクリップボードへ置く。
    /// コピーの経路をこの1本にまとめ、貼り付け結果が経路によって変わらないようにする。
    public func copyToPasteboardWithWatermark() {
        Watermark.applied(to: self).copyToGeneralPasteboard()
    }
}
