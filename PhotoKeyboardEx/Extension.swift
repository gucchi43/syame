//
//  Extension.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/04.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

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
    static let allReload = Notification.Name("allReload")
    /// 課金状態が変わったとき。既存コードが通知を使っているので方式を揃える
    static let premiumStateChanged = Notification.Name("premiumStateChanged")
    /// 案内行から「画像を入れる」を押したとき。保存の導線は親のFABが持っている
    static let requestAddPhoto = Notification.Name("requestAddPhoto")
    /// 案内をひとつ見終わったとき。閉じたあとに次の手順へ進めるために使う
    static let onboardingDidAdvance = Notification.Name("onboardingDidAdvance")
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let root = controller ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        if let navigationController = root as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = root as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = root?.presentedViewController {
            return topViewController(controller: presented)
        }
        return root
    }
}


