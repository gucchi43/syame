//
//  TestFirePhoto.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import PhotoKeyboardFramework

struct OFirePhoto: Codable, Equatable {
    var id: String
    var title: String
    var imageHeight: Int
    var imageWidth: Int
    var imageUrl: String
    var genre: String
    var totalSaveCount: Int
    var weeklySaveCount: Int
    var weekStartDay: String
    var createdAt: Timestamp
    var updateAt: Timestamp
}

final class RootStore {
    static let shared = RootStore()
    class func rootDB() -> DocumentReference {
        var mode = ""
        #if DEBUG
        mode = "/debug"
        #else
        mode = "/1"
        #endif
        var root = Firestore.firestore().document(Lang.rootKey() + mode)
//        var root = Firestore.firestore().document("official" + mode)
        return root
    }
}

