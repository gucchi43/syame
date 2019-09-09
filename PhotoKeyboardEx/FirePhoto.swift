//
//  TestFirePhoto.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation
import Firebase
import Ballcap
import PhotoKeyboardFramework

struct OFirePhoto: Codable, Equatable {
    var id: String = ""
    var title: String = ""
    var imageHeight = 0
    var imageWidth = 0
    var imageUrl: String = ""
    var genre: String = ""
    var totalSaveCount: Int = 0
    var weeklySaveCount: Int = 0
    var weekStartDay: String = ""
    var createdAt: Timestamp = Timestamp(date: Date())
    var updateAt: Timestamp = Timestamp(date: Date())
}

final class RootStore {
    static let shared = RootStore()
    class func rootDB() -> DocumentReference {
        var rootKey = ""
        let type = Bundle.main.preferredLocalizations.first!
        if type.contains("ja") {
            rootKey = "ja"
        } else {
            rootKey = "other"
        }
        print("rootKey : ", rootKey)
        var root = Firestore.firestore().document(rootKey + "/1")
//        var root = Firestore.firestore().collection(rootKey + "/1")
        return root
    }
}
