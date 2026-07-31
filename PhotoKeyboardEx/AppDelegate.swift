//
//  AppDelegate.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import UserNotifications
import PhotoKeyboardFramework
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        anonymousAuth()
        checkAppVersion()
        setLayout()
        GroupeDefaults.shared.incrementLaunchCount()
        GADMobileAds.sharedInstance().start()
        return true
    }

    func anonymousAuth() {
        Task {
            do {
                try await SupabaseManager.shared.ensureSignedIn()
            } catch {
                // 投稿時に再試行するためここでは記録のみ
                print("anonymous sign in error: \(error)")
            }
        }
    }

    private func setLayout() {
        UINavigationBar.appearance().tintColor = .acGreen()
        UINavigationBar.appearance().barTintColor = .bgDark()
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acGreen()]
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
