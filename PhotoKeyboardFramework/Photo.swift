//
//  Photo.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/04.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import RealmSwift
import SwiftDate

public class RealmPhoto: Object {
    /// 保存・投稿時のJPEG品質。
    /// 0.3 では圧縮によるブロックノイズがはっきり見えるため、実用的な範囲まで上げる。
    /// この値は投稿時のアップロードと端末内の保存の両方で使う。
    public static let jpegCompressionQuality: CGFloat = 0.85

    @objc public dynamic var id = ""
    @objc public dynamic var text = ""
    @objc public dynamic var getDay = ""
    @objc public dynamic var useNum = 0
    /// 公開投稿は廃止済み。サーバ経路自体が無いので読み手はいないが、
    /// 既定を true にしておくと将来この型を作る経路が公開扱いで始まってしまう
    @objc public dynamic var isPublic = false
    @objc public dynamic var imageHeight = 0
    @objc public dynamic var imageWidth = 0
    @objc public dynamic var ownerId = ""
    @objc dynamic private var _image: UIImage? = nil
    @objc public dynamic var image: UIImage? {
        set{
            self._image = newValue
            if let value = newValue {
                self.imageData = value.jpegData(compressionQuality: RealmPhoto.jpegCompressionQuality)
            }
        }
        get{
            if let image = self._image {
                return image
            }
            // デコード結果をインスタンスに保持すると、一覧をスクロールするだけで
            // 非圧縮ビットマップが積み上がりキーボード拡張のメモリ上限を超えるためキャッシュしない。
            guard let data = self.imageData else { return nil }
            return UIImage(data: data)
        }
    }
    @objc dynamic private var imageData: Data? = nil

    private static let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        return cache
    }()

    /// 一覧表示用の縮小画像。フル解像度をデコードせずに済むためメモリ消費を大幅に抑えられる。
    public func thumbnail(maxPixelSize: CGFloat) -> UIImage? {
        let pixelSize = max(1, Int(maxPixelSize.rounded()))
        let cacheKey = "\(id)-\(pixelSize)" as NSString
        if let cached = RealmPhoto.thumbnailCache.object(forKey: cacheKey) {
            return cached
        }
        guard let data = self.imageData as CFData?,
              let source = CGImageSourceCreateWithData(data, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cgImage)
        RealmPhoto.thumbnailCache.setObject(image, forKey: cacheKey)
        return image
    }

    
    public static func create(id: String, text: String, image: UIImage, imageHeight: Int, imageWidth: Int, getDay: String, isPublic: Bool, ownerId: String) -> RealmPhoto{
        let realmPhoto = RealmPhoto()
        realmPhoto.id = id
        realmPhoto.text = text
        realmPhoto.image = image
        realmPhoto.imageHeight = imageHeight
        realmPhoto.imageWidth = imageWidth
        realmPhoto.getDay = getDay
        realmPhoto.isPublic = isPublic
        realmPhoto.ownerId = ownerId
        return realmPhoto
    }

    //   ["image", "_image"]を無視する設定
    override public static func ignoredProperties() -> [String] {
        return ["image", "_image"]
    }

    /// 見本画像の所有者。利用者が保存したものと区別するための目印で、
    /// 枚数の上限を数えるときに除外する
    public static let officialOwnerId = "official"

    /// 利用者自身が保存したものかどうか
    public var isUserOwned: Bool {
        return ownerId != RealmPhoto.officialOwnerId
    }

    // idをプライマリキーに設定
    override public static func primaryKey() -> String? {
        return "id"
    }
}

/// チュートリアル用の初期画像。
/// officialPhotoWelcome はアプリ本体のAssetsにしか含まれずキーボード拡張からは解決できないため、
/// 強制アンラップせず画像が見つからない場合は nil を返す。
/// ID は画像ごとの固定値。投入済み判定に使うため、画像を差し替えるときは ID も新しくする。
public func makeOfficialPhoto() -> RealmPhoto? {
    guard let image = UIImage(named: "officialPhotoWelcome") else { return nil }
    return RealmPhoto.create(id: "8E988DA6-194D-47F2-8500-3384FA99B725",
                             text: "まーまーらいおん君",
                             image: image,
                             imageHeight: 800,
                             imageWidth: 800,
                             getDay: Date().toString(),
                             isPublic: false,
                             ownerId: RealmPhoto.officialOwnerId)
}
