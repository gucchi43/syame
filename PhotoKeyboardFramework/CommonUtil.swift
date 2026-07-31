//
//  CommonUtil.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/09/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

//Localizableを呼び出せるようにする設定
public class CommonUtil
{
    public static let shared = CommonUtil()
    private init(){
        bundle = Bundle(for: type(of: self))
    }
    public let bundle: Bundle
}

extension String
{
    public var localized: String
    {
        let bundle = CommonUtil.shared.bundle
        let result = NSLocalizedString(self, tableName: "Localizable", bundle: bundle, value: "", comment: self)
        return result
    }
}

/// リモート画像のキャッシュ付きローダー。
/// キャッシュがないとコレクションビューをリロードするたびに全画像を再ダウンロードしてしまう。
public final class RemoteImageLoader {
    public static let shared = RemoteImageLoader()

    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 120
        return cache
    }()
    private let session = URLSession(configuration: .default)

    private init() {}

    public func cachedImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    /// 返した task を保持しておき、セル再利用時に cancel すること。
    @discardableResult
    public func load(url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let cached = cachedImage(for: url) {
            completion(cached)
            return nil
        }
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard error == nil,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(statusCode),
                  let data = data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
