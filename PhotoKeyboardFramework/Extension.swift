//
//  Extension.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/15.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

public class Lang {
    static let shared = Lang()

    public static let japaneseRootKey = "JP"
    public static let worldRootKey = "WORLD"

    /// 端末の言語コードが日本語かどうかで判定する。
    /// 以前は rootKey() が地域コード(末尾2文字が "JP")、langRootKey() が言語コード(先頭2文字が "ja")を見ており、
    /// 地域サフィックスのない "ja" の端末でUIとデータ参照先が食い違っていた。
    public class func rootKey() -> String {
        guard let type = NSLocale.preferredLanguages.first else { return worldRootKey }
        return type.prefix(2) == "ja" ? japaneseRootKey : worldRootKey
    }

    public class func langRootKey() -> String {
        return rootKey()
    }
}

extension UIImage {
    public func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // scaleに0(デバイススケール)を渡すと3x端末で9倍のピクセル数になりメモリを浪費するため1.0で固定する
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }

    /// 画像を汎用ペーストボードへ書き込む。
    ///
    /// `UIPasteboard.typeListImage` の先頭は "public.png" のため、そこへ `jpegData(...)` の
    /// バイト列を書き込むと宣言した型と実体が食い違う。書き込み自体は成功するが、貼り付ける側は
    /// PNGとしてデコードしようとして失敗するため「コピーできたのに貼れない」状態になる。
    /// 型の指定を誤らないよう UIPasteboard の image プロパティに委ねる。
    public func copyToGeneralPasteboard() {
        UIPasteboard.general.image = self
    }

    public func composite(image: UIImage, rate: CGFloat = 1.0) -> UIImage? {
        // scaleに0(デバイススケール)を渡すと2000pxの画像で6000x6000のコンテキストを確保してしまい、
        // メモリ上限の厳しいキーボード拡張が強制終了する。1.0で固定する。
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        // 画像を右下に重ねる
        let rect = CGRect(x: (self.size.width - image.size.width * rate),
                          y: (self.size.height - image.size.height * rate),
                          width: image.size.width * rate,
                          height: image.size.height * rate)
        image.draw(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - NSAttributedString helpers (SwiftyAttributes代替)
public extension String {
    func withFont(_ font: UIFont) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: [.font: font])
    }

    func withTextColor(_ color: UIColor) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: [.foregroundColor: color])
    }
}

public extension NSAttributedString {
    func withFont(_ font: UIFont) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutable.length))
        return mutable
    }

    func withTextColor(_ color: UIColor) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutable.length))
        return mutable
    }

    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        return result
    }
}

// MARK: - Properties
public extension UICollectionView {
    
    /// SwifterSwift: Index path of last item in collectionView.
    var indexPathForLastItem: IndexPath? {
        return indexPathForLastItem(inSection: lastSection)
    }
    
    /// SwifterSwift: Index of last section in collectionView.
    var lastSection: Int {
        return numberOfSections > 0 ? numberOfSections - 1 : 0
    }
    
}

// MARK: - Methods
public extension UICollectionView {
    
    /// SwifterSwift: IndexPath for last item in section.
    ///
    /// - Parameter section: section to get last item in.
    /// - Returns: optional last indexPath for last item in section (if applicable).
    func indexPathForLastItem(inSection section: Int) -> IndexPath? {
        guard section >= 0 else {
            return nil
        }
        guard section < numberOfSections else {
            return nil
        }
        guard numberOfItems(inSection: section) > 0 else {
            return IndexPath(item: 0, section: section)
        }
        return IndexPath(item: numberOfItems(inSection: section) - 1, section: section)
    }
    
    /// SwifterSwift: Reload data with a completion handler.
    ///
    /// - Parameter completion: completion handler to run after reloadData finishes.
    func reloadData(_ completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion: { _ in
            completion()
        })
    }
}
