import UIKit
import Alamofire
import SwiftyJSON
import PhotoKeyboardFramework

// アプリバージョン管理 (Supabase app_config テーブル使用)
extension AppDelegate {

    func checkAppVersion() {
        let storeUrl = URL(string: "http://itunes.apple.com/lookup?id=1477807463")
        AF.request(storeUrl!).responseJSON { (response) in
            guard let object = response.value else { return }
            let json = JSON(object)
            guard let storeVersion = json["results"][0]["version"].string else { return }
            let currentversion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let currentArray = currentversion.split { $0 == "." }.map { String($0) }.map { Int($0) ?? 0 }
            let storeArray = storeVersion.split { $0 == "." }.map { String($0) }.map { Int($0) ?? 0 }

            guard let storeFirst = storeArray.first, let currentFirst = currentArray.first else { return }
            if storeFirst > currentFirst {
                self.mustUpdateCheck(currentVersion: currentversion)
            } else if storeArray.count > 1 && (currentArray.count <= 1 || storeArray[1] > currentArray[1]) {
                self.mustUpdateCheck(currentVersion: currentversion)
            } else if storeArray.count > 2 && (currentArray.count <= 2 || storeArray[1] == currentArray[1] && storeArray[2] > currentArray[2]) {
                self.mustUpdateCheck(currentVersion: currentversion)
            }
        }
    }

    func mustUpdateCheck(currentVersion: String) {
        let supabase = SupabaseManager.shared.client
        Task {
            do {
                let configs: [AppConfig] = try await supabase
                    .from("app_config")
                    .select()
                    .execute()
                    .value

                let configMap = Dictionary(uniqueKeysWithValues: configs.map { ($0.key, $0.value) })
                let mustUpdateVersion = configMap["must_update_ver"] ?? "1.0.0"
                let mustUpdateMessage = configMap["must_update_message"] ?? ""

                let currentArray = currentVersion.split { $0 == "." }.map { String($0) }.map { Int($0) ?? 0 }
                let mustArray = mustUpdateVersion.split { $0 == "." }.map { String($0) }.map { Int($0) ?? 0 }

                guard let mustFirst = mustArray.first, let currentFirst = currentArray.first else { return }
                if mustFirst > currentFirst {
                    await showMustUpdateAlert(message: mustUpdateMessage)
                } else if mustArray.count > 1 && (currentArray.count <= 1 || mustArray[1] > currentArray[1]) {
                    await showMustUpdateAlert(message: mustUpdateMessage)
                } else if mustArray.count > 2 && (currentArray.count <= 2 || mustArray[1] == currentArray[1] && mustArray[2] > currentArray[2]) {
                    await showMustUpdateAlert(message: mustUpdateMessage)
                } else {
                    await showUpdateAlert()
                }
            } catch {
                print("app_config fetch error: \(error)")
            }
        }
    }

    @MainActor
    func showUpdateAlert() {
        let alert = UIAlertController(
            title: "アップデートしてください",
            message: "手間かけさせて悪いね",
            preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "アプデする", style: .default) { _ in
            UIApplication.shared.open(URL(string: "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=1281328373")!)
        }
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "絶対しない", style: .destructive))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    @MainActor
    func showMustUpdateAlert(message: String) {
        let alert = UIAlertController(
            title: "アップデートしてください",
            message: message,
            preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "アプデする", style: .default) { _ in
            UIApplication.shared.open(URL(string: "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=1281328373")!)
        }
        alert.addAction(updateAction)
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

struct AppConfig: Codable {
    let key: String
    let value: String
}
