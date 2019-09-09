//
//  Extension.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/04.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import FontAwesome_swift
//import ActionClosurable

extension UIImage {
    class func imageWithLabel(_ label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

extension Notification.Name {
    static let updateSaveState = Notification.Name("updateSaveState")
    static let finishUpload = Notification.Name("finishUpload")
    static let allRelaod = Notification.Name("allRelaod")
}

