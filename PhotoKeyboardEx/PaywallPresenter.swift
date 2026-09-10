//
//  PaywallPresenter.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// ペイウォールの出し方を1箇所にまとめる。
///
/// 上限に当たった瞬間の文脈的な訴求は、汎用的な案内より転換率が大きく高い。
/// 入口が増えても同じ見せ方になるよう、アラートの組み立てごとここに置く。
@MainActor
enum PaywallPresenter {

    /// ペイウォールを出す
    static func present(from viewController: UIViewController) {
        let paywall = PaywallViewController()
        let nav = UINavigationController(rootViewController: paywall)
        viewController.present(nav, animated: true)
    }

    /// 上限に達したことを伝え、そのままプレミアムへ案内する。
    /// 逃げ道(閉じる)を必ず残す
    static func presentLimitReached(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: LocalizeKey.limitReachedTitle.localizedString(PhotoQuota.freeLimit),
            message: LocalizeKey.limitReachedMessage.localizedString(),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.paywallSeePremium.localizedString(),
                                      style: .default) { _ in
            present(from: viewController)
        })
        alert.addAction(UIAlertAction(title: LocalizeKey.paywallClose.localizedString(), style: .cancel))
        viewController.present(alert, animated: true)
    }

    /// 加入済みの人に購入を勧めない。状態だけ見せる
    static func presentActiveState(from viewController: UIViewController) {
        let alert = UIAlertController(title: LocalizeKey.premiumActiveTitle.localizedString(),
                                      message: LocalizeKey.premiumActiveMessage.localizedString(),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default))
        viewController.present(alert, animated: true)
    }
}
