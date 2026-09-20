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
    ///
    /// 利用者の画像を先頭から取る。足りないぶんは、**最初の1枚だけ見本**で埋め、
    /// 残りは空きスロットにする。同じ見本を3枚並べると「もう3枚持っている」と
    /// 読めてしまい、これから入れる場所があることが伝わらない。
    /// 空のまま描くと、キーボードに何も並んでいない絵になって手順が伝わらない。
    static func slots(userPhotos: [UIImage], fallback: UIImage) -> [UIImage] {
        var slots = Array(userPhotos.prefix(slotCount))
        if slots.isEmpty {
            slots.append(fallback)
        }
        while slots.count < slotCount {
            slots.append(emptySlotImage())
        }
        return slots
    }

    /// 「ここに自分の画像が入る」ことを示す空きスロット。
    /// 破線の枠だけを描く。塗ると写真が入っているように見える
    static func emptySlotImage(side: CGFloat = 120) -> UIImage {
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.setStrokeColor(UIColor.textSecondary.withAlphaComponent(0.5).cgColor)
            cg.setLineWidth(side * 0.02)
            cg.setLineDash(phase: 0, lengths: [side * 0.08, side * 0.06])
            let inset = side * 0.06
            let rect = CGRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
            cg.addPath(UIBezierPath(roundedRect: rect, cornerRadius: side * 0.12).cgPath)
            cg.strokePath()
        }
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

    /// 図に出す画像と題名。
    ///
    /// 利用者が自分で保存したものがあれば、その画像と本人が付けた題名を使う。
    /// まだ無ければ紹介用の決まった絵に差し替える。空きスロットを並べるより、
    /// 何が起きるかが伝わる。
    static func currentGallery(maxPixelSize: CGFloat) -> (photos: [UIImage], titles: [String]) {
        let saved = Array(RealmManager.shared.realmData).filter { $0.isUserOwned }
        guard !saved.isEmpty else {
            return (GuideSampleGallery.photos, GuideSampleGallery.titles)
        }
        let picked = saved.prefix(slotCount)
        var photos = picked.compactMap { $0.thumbnail(maxPixelSize: maxPixelSize) }
        var titles = picked.map { $0.text }
        // 足りないぶんは紹介用で埋める。図の形を保つため
        let sample = GuideSampleGallery.photos
        let sampleTitles = GuideSampleGallery.titles
        var index = 0
        while photos.count < slotCount && index < sample.count {
            photos.append(sample[index])
            titles.append(sampleTitles[index])
            index += 1
        }
        return (photos, titles)
    }

    /// 図に出す画像を、いま端末にあるものから決める。
    /// 見本のアセットはアプリ本体にしか無いため、解決できないときは空を返さず
    /// 単色で埋めて図の形だけは保つ(空のキーボードを見せるより崩れが小さい)。
    static func currentSlots(maxPixelSize: CGFloat) -> [UIImage] {
        let photos = Array(RealmManager.shared.realmData)
        // 見本もサムネイルに落としてから渡す。図に出るのは数十ptなので、
        // フル解像度(800x800)を抱えたままにする理由がない
        let sample = UIImage(named: "officialPhotoWelcome")
        let fallback = sample?.resize(size: CGSize(width: maxPixelSize, height: maxPixelSize))
            ?? sample
            ?? UIImage.filled(color: .keyboardSurface)
        return slots(userPhotos: userImages(from: photos, maxPixelSize: maxPixelSize),
                     fallback: fallback)
    }
}

private extension UIImage {
    static func filled(color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
