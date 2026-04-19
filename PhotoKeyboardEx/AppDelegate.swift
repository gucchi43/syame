//
//  AppDelegate.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import Alamofire
import SwiftyJSON
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

    override init() {
        super.init()
    }

    func anonymousAuth() {
        let supabase = SupabaseManager.shared.client
        Task {
            do {
                let session = try await supabase.auth.session
                let uid = session.user.id.uuidString
                print(uid, ", login")
                GroupeDefaults.shared.setAuthUid(id: uid)
            } catch {
                do {
                    let session = try await supabase.auth.signInAnonymously()
                    let uid = session.user.id.uuidString
                    GroupeDefaults.shared.setAuthUid(id: uid)
                    print("anonymous sign in success: \(uid)")
                } catch {
                    print("anonymous sign in error: \(error)")
                }
            }
        }
    }

    private func setLayout() {
        UINavigationBar.appearance().tintColor = .acGreen()
        UINavigationBar.appearance().barTintColor = .bgDark()
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.acGreen()]
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        #if DEBUG
        checkLangAlert()
        #endif
    }

    func checkLangAlert() {
        let langFirstFromLocale: String = NSLocale.preferredLanguages.first!
        let langFirstFromBundle: String = Bundle.main.preferredLocalizations.first!

        let alertController = UIAlertController(title: "SettingCheck", message: String(format: "NSLocale:%@\n NSBundle:%@", langFirstFromLocale, langFirstFromBundle), preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)

        if let topController = UIApplication.topViewController() {
            topController.present(alertController, animated: true, completion: nil)
        }
    }
}
