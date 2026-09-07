//
//  GuidePhotoSource.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 案内図に流し込む画像を決める。
enum GuidePhotoSource {

    /// 図に並べる枚数。
    static let slotCount = 3

    /// 図に並べる画像を決める。
    /// 利用者の画像を先頭から取り、`slotCount` に満たないぶんを見本で埋める。
    /// 空のまま描くと、キーボードに何も並んでいない絵になって手順が伝わらない。
    static func slots(userPhotos: [UIImage], fallback: UIImage) -> [UIImage] {
        var slots = Array(userPhotos.prefix(slotCount))
        while slots.count < slotCount {
            slots.append(fallback)
        }
        return slots
    }

    /// 利用者自身が保存した画像だけを、ボードに並ぶ順で取り出す。
    /// 見本は起動時に必ず投入されるため、除外しないと「利用者の画像が0枚」を表現できず
    /// 補填が働かない。フル解像度ではなく縮小版を使う(図に出すのは数十ptのため)。
    static func userImages(from photos: [RealmPhoto], maxPixelSize: CGFloat) -> [UIImage] {
        return photos
            .filter { $0.isUserOwned }
            .prefix(slotCount)
            .compactMap { $0.thumbnail(maxPixelSize: maxPixelSize) }
    }
}
