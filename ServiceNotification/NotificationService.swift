//
//  NotificationService.swift
//  ServiceNotification
//
//  Created by Hiroki Taniguchi on 2019/09/15.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UserNotifications
import UniformTypeIdentifiers

class NotificationService: UNNotificationServiceExtension {

    /// 通知拡張のメモリ上限は約24MB。大きな画像を掴むと表示前に強制終了する。
    private static let maxImageByteCount = 5 * 1024 * 1024

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var session: URLSession?
    private var task: URLSessionDataTask?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        let content = (request.content.mutableCopy() as? UNMutableNotificationContent)
        bestAttemptContent = content

        // 添付画像がないペイロードはそのまま配信する
        guard let content = content,
              let imageUrl = request.content.userInfo["imageUrl"] as? String,
              // リモート由来の文字列。不正な値で拡張がクラッシュしないよう強制アンラップしない。
              let url = URL(string: imageUrl),
              url.scheme == "https" else {
            deliver()
            return
        }

        let session = URLSession(configuration: .default)
        self.session = session
        task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.deliver() }

            guard error == nil,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200..<300).contains(statusCode),
                  let data = data,
                  data.count <= NotificationService.maxImageByteCount else {
                return
            }

            // ファイル名を固定にすると同時に届いた通知同士で書き込みが競合する
            let fileExtension = NotificationService.fileExtension(for: response)
            let writePath = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            do {
                try data.write(to: writePath)
                let attachment = try UNNotificationAttachment(identifier: writePath.lastPathComponent,
                                                              url: writePath,
                                                              options: nil)
                content.attachments = [attachment]
            } catch {
                try? FileManager.default.removeItem(at: writePath)
            }
        }
        task?.resume()
    }

    // 画像ダウンロードの時間切れ
    override func serviceExtensionTimeWillExpire() {
        // 残しておくと contentHandler が二重に呼ばれる
        task?.cancel()
        deliver()
    }

    /// contentHandler は一度しか呼べないため、呼び出し後に破棄する
    private func deliver() {
        guard let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent else { return }
        self.contentHandler = nil
        session?.finishTasksAndInvalidate()
        session = nil
        contentHandler(bestAttemptContent)
    }

    /// 拡張子が実体と食い違うと UNNotificationAttachment の検証で弾かれる
    private static func fileExtension(for response: URLResponse?) -> String {
        guard let mimeType = response?.mimeType,
              let type = UTType(mimeType: mimeType),
              let preferred = type.preferredFilenameExtension else {
            return "jpg"
        }
        return preferred
    }
}
