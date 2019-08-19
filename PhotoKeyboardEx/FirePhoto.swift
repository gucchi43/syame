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

struct FirePhoto: Codable, Equatable, Modelable {
    
    var title: String = ""
    var imageHeight = 0
    var imageWidth = 0
    var image: File?
    var genre: String = ""
    var saveCount: Int = 0
}

// sort用extension
extension Array {
    mutating func sortedTime(order: Bool) {
        let beforeArraey = self as! [Document<FirePhoto>]
        if order {
            self = beforeArraey.sorted {$0.createdAt > $1.createdAt} as! Array<Element>
        } else {
            self = beforeArraey.sorted {$0.createdAt < $1.createdAt} as! Array<Element>
        }
    }
    
    func sortSaveCount<T>(before: [Document<T>], order: Bool) -> [Document<T>] {
        let beforeArraey = before as! [Document<FirePhoto>]
        if order {
            let after = beforeArraey.sorted {$0.data!.saveCount > $1.data!.saveCount}
            return after as! [Document<T>]
        } else {
            let after = beforeArraey.sorted {$0.data!.saveCount < $1.data!.saveCount}
            return after as! [Document<T>]
        }
    }
}
