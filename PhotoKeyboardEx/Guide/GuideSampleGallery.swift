//
//  GuideSampleGallery.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 起動直後の図に出す紹介用の画像。
///
/// 利用者の保存画像を使う図(使い方の案内)とは役割が違う。まだ1枚も持って
/// いない人へ「こういうものが貼れる」と見せるための例なので、決まった絵を置く。
/// 素材は App Store の入稿画像から取っており、出どころは自前。
enum GuideSampleGallery {

    private static let names = ["sample_cat", "sample_food", "sample_town"]

    /// 実物のキーボードはセルに題名が付く。例にも付けて同じ見た目にする
    static var titles: [String] {
        return [LocalizeKey.sampleTitleCat.localizedString(),
                LocalizeKey.sampleTitleFood.localizedString(),
                LocalizeKey.sampleTitleTown.localizedString()]
    }

    /// 紹介用の画像。解決できないものは落として、あるものだけ返す
    static var photos: [UIImage] {
        return names.compactMap { UIImage(named: $0) }
    }

    /// トークへ送った1枚として見せる画像
    static var sentPhoto: UIImage? {
        return UIImage(named: "sample_dog")
    }
}
