//
//  AppDelegate.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import IQKeyboardManagerSwift
import Firebase
import Alamofire
import SwiftyJSON
import GoogleMobileAds
import SwiftyUserDefaults
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var remoteConfig: RemoteConfig!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        // 省略
        setRemoteConfig()
        setLayout()
        IQKeyboardManager.shared.enable = true
        GroupeDefaults.shared.incrementLaunchCount()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
//        setRemoteConfig()
        configureNotification()
        return true
    }
    
    override init() {
        super.init()
        //        Firebas   if FirebaseApp.app() == nil {
//        FirebaseApp.configuzre()
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//        // 省略
//        setRemoteConfig()
    }
    
    private func setLayout() {
        UINavigationBar.appearance().tintColor = .acGreen()
        UINavigationBar.appearance().barTintColor = .bgDark()
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acGreen()]
//        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        UINavigationBar.appearance().shadowImage = UIImage()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
         //環境言語取得テストコード
        let langFirstFromLocale:String = NSLocale.preferredLanguages.first!
        let langFirstFromBundle:String = Bundle.main.preferredLocalizations.first!
        
        let alertController = UIAlertController(title: "SettingCheck", message: String(format: "NSLocale:%@\n NSBundle:%@",langFirstFromLocale, langFirstFromBundle), preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        let activeVc = UIApplication.shared.keyWindow?.rootViewController
        
        
        activeVc?.present(alertController, animated: true, completion: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// プッシュ通知許可関連
extension AppDelegate {
    func configureNotification() {
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//            if granted {
//                print("プッシュ通知ダイアログ 許可")
//                UIApplication.shared.registerForRemoteNotifications()
//            } else {
//                print("プッシュ通知ダイアログ 拒否")
//            }
//        })
//        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
        }
    }
    
    // システムへのプッシュ通知の登録が失敗した時の処理を行う。
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("fail register notification : ", error)
    }
    
    // Device Token を取得した時の処理を行う。
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
        // ex) topicKey = local_JP, or local_WORLD
        let topicKey = "local_" + Lang.rootKey()
        Messaging.messaging().subscribe(toTopic: topicKey) { (error) in
            if error == nil {
                print("success set topic :", topicKey)
            }
        }
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    // iOS 10 以降では通知を受け取るとこちらのデリゲートメソッドが呼ばれる。
    // foreground で受信
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        // Push Notifications のmessageを取得
        let badge = content.badge
        let body = notification.request.content.body
//        let toOriginId = content.userInfo["toUserOriginId"] as! String
        print("content : ", content)
        print("userNotificationCenterのwillPresentから: \(body), \(badge)")
        //NotificationCenter飛ばす
        //        let center = NotificationCenter.default
        //        center.post(name: .receiveHotwordNotification, object: nil, userInfo: userInfo)
        showNotificationAlert(userInfo: content.userInfo)
        completionHandler([])
    }
    
    // background で受信してアプリを起動
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Push Notifications のmessageを取得
        let content = response.notification.request.content
        let badge = content.badge
        let body = response.notification.request.content.body
//        let toOriginId = content.userInfo["toUserOriginId"] as! String
        print("userNotificationCenterのdidReceiveから: \(body), \(badge)")
        print("content : ", content)
        //NotificationCenter飛ばす
//        let center = NotificationCenter.default
//        center.post(name: .receiveHotwordNotification, object: nil, userInfo: userInfo)
        showNotificationAlert(userInfo: content.userInfo)
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("remoteMessage.appData: \(remoteMessage.appData)")
    }
}

extension AppDelegate {
    func showNotificationAlert(userInfo: [AnyHashable : Any]) {
        print("userInfo のデータ: ", userInfo)
        let alert = UIAlertController(title: "Top weekly ranking photo 👑", message: "GET! GET! GET!", preferredStyle: .alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "GET!", style: .default) { (action) in
            print("SAVE Photo")
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cansell", style: .destructive) { (action) in
            print("Cancel")
        }
        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        if let topController = UIApplication.topViewController() {
            topController.present(alert, animated: true, completion: nil)
        }
    }
}

