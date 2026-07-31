//
//  AppDelegate.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import UserNotifications
import AppTrackingTransparency
import PhotoKeyboardFramework
import GoogleMobileAds
import UserMessagingPlatform

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
        requestAdConsentThenStartAds()
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

    /// 広告の同意取得と初期化。
    ///
    /// GDPR等の対象地域では、広告を出す前に UMP で同意を取る必要がある。
    /// また iOS 14.5 以降、IDFA を使うには ATT の許諾が必要で、
    /// これを取らずに広告SDKを動かすと審査で弾かれる。
    /// 同意フォームの結果に関わらず広告自体は初期化する(非パーソナライズ広告になる)。
    private func requestAdConsentThenStartAds() {
        let parameters = UMPRequestParameters()
        #if DEBUG
        // 実機で同意フォームを確認できるようにする
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        #endif

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            if let error = error {
                print("UMP consent info error: \(error)")
                self?.requestTrackingAuthorizationThenStartAds()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: nil) { [weak self] formError in
                if let formError = formError {
                    print("UMP consent form error: \(formError)")
                }
                self?.requestTrackingAuthorizationThenStartAds()
            }
        }
    }

    private func requestTrackingAuthorizationThenStartAds() {
        // UMPの同意フォームと重ならないよう、フォームを閉じてから要求する
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                GADMobileAds.sharedInstance().start(completionHandler: nil)
                NotificationCenter.default.post(name: .adsDidStart, object: nil)
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
