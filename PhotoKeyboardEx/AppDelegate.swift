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
        if let keyboardResult = GroupeDefaults.shared.lastKeyboardOpenResult() {
            print("[keyboard openURL] \(keyboardResult)")
        }
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

    /// キーボード拡張から渡されたURLを開く。
    /// 拡張から外部URL(LINEなど)を直接開けない場合に、
    /// photokeyboardex-app://open?url=... の形でアプリへ委譲されてくる。
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let forwarded = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let target = URL(string: forwarded) else {
            // スキームだけで開かれた場合はアプリを起動するだけでよい
            return true
        }
        UIApplication.shared.open(target, options: [:], completionHandler: nil)
        return true
    }
}
