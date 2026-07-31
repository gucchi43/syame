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

extension UIApplication {
    /// 公式LINEを開く。
    /// インストール済みならSafariを経由せず直接アプリを開き、無ければWebにフォールバックする。
    /// canOpenURL には Info.plist の LSApplicationQueriesSchemes への登録が必要。
    func openOfficialLINE(completion: ((Bool) -> Void)? = nil) {
        if let appURL = OfficialLINE.appURL, canOpenURL(appURL) {
            open(appURL, options: [:], completionHandler: completion)
            return
        }
        guard let webURL = OfficialLINE.webURL else {
            completion?(false)
            return
        }
        open(webURL, options: [:], completionHandler: completion)
    }
}

extension Notification.Name {
    static let updateSaveState = Notification.Name("updateSaveState")
    static let finishUpload = Notification.Name("finishUpload")
    static let allRelaod = Notification.Name("allRelaod")
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


