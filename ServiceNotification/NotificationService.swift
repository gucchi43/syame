//
//  NotificationService.swift
//  ServiceNotification
//
//  Created by Hiroki Taniguchi on 2019/09/15.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let imageUrl = request.content.userInfo["imageUrl"] as? String {
            let session = URLSession(configuration: URLSessionConfiguration.default)
            let task = session.dataTask(with: URL(string: imageUrl)!, completionHandler: { (data, response, error) in
                do {
                    if let writePath = NSURL(fileURLWithPath:NSTemporaryDirectory())
                        .appendingPathComponent("tmp.jpg") {
                        try data?.write(to: writePath)
                        
                        if let bestAttemptContent = self.bestAttemptContent {
//                            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                            let attachment = try UNNotificationAttachment(identifier: "tiqav", url: writePath, options: nil)
                            bestAttemptContent.attachments = [attachment]
                            contentHandler(bestAttemptContent)
                        }
                    } else {
                        // error: writePath is not URL
                        if let bestAttemptContent = self.bestAttemptContent {
                            contentHandler(bestAttemptContent)
                        }
                    }
                } catch _ {
                    // error: data write error or create UNNotificationAttachment error
                    if let bestAttemptContent = self.bestAttemptContent {
                        contentHandler(bestAttemptContent)
                    }
                }
            })
            task.resume()
        } else {
            if let bestAttemptContent = self.bestAttemptContent {
                bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    
    // 画像ダウンロードの時間切れ
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
