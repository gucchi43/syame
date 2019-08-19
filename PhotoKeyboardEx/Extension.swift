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
    static let updateListButton = Notification.Name("updateListButton")
}

//public struct FontAwesome {
//    public enum Style {
//        case solid, regular // brands はお好みで
//
//        public var fontName: String {
//            switch self {
//            case .solid: return "FontAwesome5FreeSolid"
//            case .regular: return "FontAwesome5FreeRegular"
//            }
//        }
//    }
//    public static func font(size: CGFloat, style: Style = .solid) -> UIFont {
//        return UIFont(name: style.fontName, size: size)!
//    }
//
//    public struct Icon {
//        let code: String
//
//        public static let bars = Icon(code: "bars")
//        public static let star = Icon(code: "star")
//    }
//}

//extension NSAttributedString {
//    public static func icon(
//        _ icon: FontAwesome.Icon,
//        size: CGFloat,
//        style: FontAwesome.Style = .solid)
//        -> NSAttributedString {
//            return NSAttributedString(
//                string: icon.code,
//                attributes: [
//                    .font : FontAwesome.font(size: size, style: style)
//                ]
//            )
//    }
//}

//extension UIBarButtonItem {
//    public convenience init(
//    )
//    public convenience init(
//        icon: FontAwesome.Icon,
//        closure: @escaping (UIBarButtonItem) -> Void
//        ) {
//        self.init(barButtonSystemItem: icon.code,
//                  target: .done,
//                  action: closure) // ※
//
//        let states: [UIControl.State] = [
//            .normal, .highlighted, .disabled, .focused
//        ]
//        states.forEach {
//            self.setTitleTextAttributes([
//                .font : FontAwesome.font(size: 26)
//                ], for: $0)
//        }
//    }
//}
