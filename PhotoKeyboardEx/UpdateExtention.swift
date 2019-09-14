//
//  UpdateExtention.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/09/12.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import FirebaseRemoteConfig
import Alamofire
import SwiftyJSON

// RemoteConfigでの強制アップデート周り
extension AppDelegate {
    func setRemoteConfig() {
        // RemoteConfigの設定
        remoteConfig = RemoteConfig.remoteConfig()
        // デバッグモードの有効化
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        // デフォルト値のセット
        remoteConfig.setDefaults(["must_update_ver": "1.0.0" as NSObject])
        remoteConfig.setDefaults(["must_update_message": "おねがーい" as NSObject])
        checkAppVersion()
    }
    
    func checkAppVersion() {
        let storeUrl = URL(string: "http://itunes.apple.com/lookup?id=1477807463")
        AF.request(storeUrl!).responseJSON { (response) in
            guard let object = response.value else{
                return
            }
            //現アプリのバージョン(currentversion)とApp Storeの最新のバージョン(latestVersion)を取得する
            let json = JSON(object)
            guard let storeVersion = json["results"][0]["version"].string else { return }
            let currentversion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            //バージョンのフォーマットをIntの配列に変更する ex) 1.2.3 → [1, 2, 3]
            let currentArray = currentversion.split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
            let storeArray = storeVersion.split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
            print("currentArray", currentArray)
            print("storeVersion", storeVersion)
            //App Storeの最新のバージョンが、現アプリよりもバージョンが上のときのみアラートを出すためのチェック
            guard let storeArrayFirst = storeArray.first, let currentArrayFirst = currentArray.first else {
                print("特定のバージョンがない")
                return
            }
            if storeArrayFirst > currentArrayFirst { // A.b.c
                print("AppStoreのMajorVersionが大きい A.b.c")
                self.mustUpdateCheck(currentVersion: currentversion)
            } else if storeArray.count > 1 && (currentArray.count <= 1 || storeArray[1] > currentArray[1]) { // a.B.c
                print("AppStoreのMinorVersionが大きい a.B.c")
                self.mustUpdateCheck(currentVersion: currentversion)
            } else if storeArray.count > 2 && (currentArray.count <= 2 || storeArray[1] == currentArray[1] && storeArray[2] > currentArray[2]) { // a.b.C
                print("AppStoreのRevisionが大きい a.b.C")
                self.mustUpdateCheck(currentVersion: currentversion)
            }  else {
                print("This versiosn is latest")
            }
        }
    }
    
    func mustUpdateCheck(currentVersion: String) {
        
        // TimeInterval is set to expirationDuration here, indicating the next fetch request will use
        // data fetched from the Remote Config service, rather than cached parameter values, if cached
        // parameter values are more than expirationDuration seconds old. See Best Practices in the
        let expirationDuration = remoteConfig.configSettings.isDeveloperModeEnabled ? 0 : 3600
        remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
            //        remoteConfig.fetch { (status, error) in
            
            print("====================")
            print("error :", error)
            print("status :", status)
            print("====================")
            
            if (status == RemoteConfigFetchStatus.success) {
                // フェッチ成功
                print("Config fetched!")
                self.remoteConfig.activate(completionHandler: { (error) in
                    if let error = error {
                        print("error : ", error)
                    } else {
                        let mustUpdateVersion = self.remoteConfig["must_update_ver"].stringValue!
                        let mustUpdateMessage = self.remoteConfig["must_update_message"].stringValue!
                        print("mustUpdateVersion : ", mustUpdateVersion)
                        //バージョンのフォーマットをIntの配列に変更する ex) 1.2.3 → [1, 2, 3]
                        let currentArray = currentVersion.split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
                        let mustUpdateArray = mustUpdateVersion.split {$0 == "."}.map { String($0) }.map {Int($0) ?? 0}
                        guard let mustUpdateArrayFirst = mustUpdateArray.first, let currentArrayFirst = currentArray.first else {
                            print("特定のバージョンがない")
                            return
                        }
                        if mustUpdateArrayFirst > currentArrayFirst { // A.b.c
                            self.showMustUpdateAlert(message: mustUpdateMessage)
                        } else if mustUpdateArray.count > 1 && (currentArray.count <= 1 || mustUpdateArray[1] > currentArray[1]) { //a.B.c
                            self.showMustUpdateAlert(message: mustUpdateMessage)
                        } else if mustUpdateArray.count > 2 && (currentArray.count <= 2 || mustUpdateArray[1] == currentArray[1] && mustUpdateArray[2] > currentArray[2]) { // a.b.C
                            self.showMustUpdateAlert(message: mustUpdateMessage)
                        }  else {
                            self.showUpdateAlert()
                        }
                    }
                })
            } else {
                // フェッチ失敗
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
        }
    }
    
    func showUpdateAlert() {
        let alert = UIAlertController(
            title: "アップデートしてください",
            message: "手間かけさせて悪いね",
            preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "アプデする", style: .default) {
            action in
            UIApplication.shared.open(URL(string: "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=1281328373")!)
        }
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "絶対しない", style: .destructive))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func showMustUpdateAlert(message: String) {
        let alert = UIAlertController(
            title: "アップデートしてください",
            message: message,
            preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "アプデする", style: .default) {
            action in
            UIApplication.shared.open(URL(string: "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=1281328373")!)
        }
        alert.addAction(updateAction)
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
