//
//  OnboardingCelebration.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 設定が全部終わったことを伝え、そのまま試しに行ってもらう。
///
/// 準備が終わった瞬間が、実際に使ってみる気のいちばん強いところ。
/// ここで「どこで使えばいいのか」を出さないと、ボードに戻って終わってしまう。
@MainActor
enum OnboardingCelebration {

    /// 試し先の候補。入っているものだけ出す
    private enum Destination: CaseIterable {
        case line
        case instagram

        var scheme: String {
            switch self {
            case .line: return "line://"
            case .instagram: return "instagram://"
            }
        }

        /// 起動できないときの逃げ先。アプリが入っていなくても案内は成立させる
        var webFallback: String {
            switch self {
            case .line: return "https://line.me/"
            case .instagram: return "https://www.instagram.com/"
            }
        }

        var titleKey: LocalizeKey {
            switch self {
            case .line: return .celebrateOpenLine
            case .instagram: return .celebrateOpenInstagram
            }
        }

        /// 入っているか。Info.plist の LSApplicationQueriesSchemes に
        /// 登録していない scheme は、入っていても常に false になる
        var isInstalled: Bool {
            guard let url = URL(string: scheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    static func present(from viewController: UIViewController) {
        let alert = UIAlertController(title: LocalizeKey.celebrateTitle.localizedString(),
                                      message: LocalizeKey.celebrateMessage.localizedString(),
                                      preferredStyle: .alert)

        // 入っているものだけ並べる。持っていないアプリを勧めても押せない
        let installed = Destination.allCases.filter { $0.isInstalled }
        let shown = installed.isEmpty ? Destination.allCases : installed
        for destination in shown {
            alert.addAction(UIAlertAction(title: destination.titleKey.localizedString(),
                                          style: .default) { _ in
                open(destination)
            })
        }
        alert.addAction(UIAlertAction(title: LocalizeKey.celebrateLater.localizedString(),
                                      style: .cancel))
        viewController.present(alert, animated: true)
    }

    private static func open(_ destination: Destination) {
        if let url = URL(string: destination.scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        // アプリが無ければ web へ。押して何も起きないのが一番良くない
        guard let fallback = URL(string: destination.webFallback) else { return }
        UIApplication.shared.open(fallback)
    }
}
