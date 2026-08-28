import UIKit
import PhotoKeyboardFramework

// アプリバージョン管理。ストアの最新版を itunes lookup で調べ、古ければ案内する。
//
// 以前は「この版はもう使わせない」という強制アップデートの判定を Supabase の
// app_config テーブルから引いていたが、Supabase のプロジェクトが消滅しており、
// 取得失敗を握りつぶしていたため案内自体が一度も出ない状態になっていた。
// 強制の区別が再び必要になったら、静的な JSON を1本置いて読むだけで足りる。
extension AppDelegate {

    /// App Store のアプリID。lookup と itms-apps の遷移先で別々のIDを使っていたため一箇所にまとめる。
    private static let appStoreId = "1477807463"

    private struct LookupResponse: Decodable {
        struct Result: Decodable {
            let version: String
        }
        let results: [Result]
    }

    func checkAppVersion() {
        // http:// のままだと ATS にブロックされ、バージョンチェックが無言で機能しなくなる
        guard let storeUrl = URL(string: "https://itunes.apple.com/lookup?id=\(AppDelegate.appStoreId)"),
              let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: storeUrl)
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                      (200..<300).contains(statusCode) else { return }
                let lookup = try JSONDecoder().decode(LookupResponse.self, from: data)
                guard let storeVersion = lookup.results.first?.version else { return }
                guard AppDelegate.isVersion(currentVersion, olderThan: storeVersion) else { return }
                await showUpdateAlert()
            } catch {
                print("app version check error: \(error)")
            }
        }
    }

    /// "1.9.0" と "2.0.0" のようにメジャー番号だけが違うケースも正しく比較する
    static func isVersion(_ lhs: String, olderThan rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue != rightValue { return leftValue < rightValue }
        }
        return false
    }

    @MainActor
    private func openAppStore() {
        guard let url = URL(string: "itms-apps://apps.apple.com/app/id\(AppDelegate.appStoreId)") else { return }
        UIApplication.shared.open(url)
    }

    @MainActor
    func showUpdateAlert() {
        let alert = UIAlertController(
            title: LocalizeKey.updateAlertTitle.localizedString(),
            message: LocalizeKey.updateAlertMessage.localizedString(),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.updateAlertUpdate.localizedString(), style: .default) { [weak self] _ in
            self?.openAppStore()
        })
        alert.addAction(UIAlertAction(title: LocalizeKey.updateAlertLater.localizedString(), style: .cancel))
        present(alert)
    }

    /// rootViewController が既に別の画面を表示していると present に失敗するため最前面を使う
    @MainActor
    private func present(_ alert: UIAlertController) {
        guard let topController = UIApplication.topViewController() else { return }
        topController.present(alert, animated: true, completion: nil)
    }
}
