//
//  Photo.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/04.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import RealmSwift
import Realm

public class RealmPhoto: Object {
    // TESTデータ削除用
    @objc public dynamic var reset = ""
    
    @objc public dynamic var id = ""
    @objc public dynamic var text = ""
    @objc public dynamic var getDay = ""
    @objc public dynamic var useNum = 0
    @objc public dynamic var isSelected = false
    @objc public dynamic var imageHeight = 0
    @objc public dynamic var imageWidth = 0
    @objc dynamic private var _image: UIImage? = nil
    @objc public dynamic var image: UIImage? {
        set{
            self._image = newValue
            if let value = newValue {
//                self.imageData = value.pngData()
                self.imageData = value.jpegData(compressionQuality: 1.0)
            }
        }
        get{
            if let image = self._image {
                return image
            }
            if let data = self.imageData {
                self._image = UIImage(data: data)
                return self._image
            }
            return nil
        }
    }
    @objc dynamic private var imageData: Data? = nil

    
    public static func create(id: String, text: String, image: UIImage, imageHeight: Int, imageWidth: Int, getDay: String) -> RealmPhoto{
        let realmPhoto = RealmPhoto()
        realmPhoto.id = id
        realmPhoto.text = text
        realmPhoto.image = image
        realmPhoto.imageHeight = imageHeight
        realmPhoto.imageWidth = imageWidth
        realmPhoto.getDay = getDay
        return realmPhoto
    }
    
//    convenience init(name: String) {
//        self.init()
//        self.name = name
//    }
    //   ["image", "_image"]を無視する設定
    override public static func ignoredProperties() -> [String] {
        return ["image", "_image", "isSelected"]
    }

    // idをプライマリキーに設定
    override public static func primaryKey() -> String? {
        return "id"
    }
}
