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
import Realm
import SwiftDate

public class RealmPhoto: Object {
    // TESTデータ削除用
//    @objc public dynamic var reset = ""
    
    @objc public dynamic var id = ""
    @objc public dynamic var text = ""
    @objc public dynamic var getDay = ""
    @objc public dynamic var useNum = 0
    @objc public dynamic var isPublic = true
    @objc public dynamic var imageHeight = 0
    @objc public dynamic var imageWidth = 0
    @objc public dynamic var ownerId = ""
    @objc dynamic private var _image: UIImage? = nil
    @objc public dynamic var image: UIImage? {
        set{
            self._image = newValue
            if let value = newValue {
//                self.imageData = value.pngData()
                self.imageData = value.jpegData(compressionQuality: 0.3)
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
    
//    convenience init(name: String) {
//        self.init()
//        self.name = name
//    }
    //   ["image", "_image"]を無視する設定
    override public static func ignoredProperties() -> [String] {
        return ["image", "_image"]
    }

    // idをプライマリキーに設定
    override public static func primaryKey() -> String? {
        return "id"
    }
}

/// チュートリアル用の初期画像。
/// officialPhotoFirst はアプリ本体のAssetsにしか含まれずキーボード拡張からは解決できないため、
/// 強制アンラップせず画像が見つからない場合は nil を返す。
public func makeOfficialPhoto() -> RealmPhoto? {
    guard let image = UIImage(named: "officialPhotoFirst") else { return nil }
    return RealmPhoto.create(id: "A04C59BD-F2CC-43ED-B0B5-39E55A03E283",
                             text: "おもんない！",
                             image: image,
                             imageHeight: 600,
                             imageWidth: 532,
                             getDay: Date().toString(),
                             isPublic: false,
                             ownerId: "official")
}
