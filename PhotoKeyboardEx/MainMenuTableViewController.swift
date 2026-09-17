//
//  MainMenuTableViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/03.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

class MyMenuTableViewController: UITableViewController {
    
    private let menuOptionCellId = "Cell"
    var selectedMenuItem : Int = 0
    
    var menuWidth: CGFloat = 180.0

    /// ナビゲーションスタックを壊さないため子VCにはしていないので、参照を直接持つ
    weak var sideMenuHost: MainNavigationViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // 上端の余白は viewDidLayoutSubviews でナビゲーションバーの実寸から決める
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.scrollsToTop = false
        clearsSelectionOnViewWillAppear = false
        tableView.selectRow(at: IndexPath(row: selectedMenuItem, section: 0), animated: false, scrollPosition: .middle)
        // 課金の行の文言は加入状態で変わる。このビューは一度敷いたら作り直されないため、
        // 通知を受けて引き直さないと購入後もずっと勧誘のままになる
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(reloadForPremiumChange),
                                              name: .premiumStateChanged,
                                              object: nil)
    }

    @objc private func reloadForPremiumChange() {
        tableView.reloadData()
        tableView.selectRow(at: IndexPath(row: selectedMenuItem, section: 0),
                            animated: false, scrollPosition: .none)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 行数が少ないと自動インセットが効かず、最初の行がナビゲーションバーと重なる。
        // バーの下端を実測して確実に下げる。
        let navBottom = sideMenuHost?.navigationBar.frame.maxY ?? view.safeAreaInsets.top
        let top = navBottom + Spacing.l
        if tableView.contentInset.top != top {
            tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// 行の並び。row の数値を直に書くと3箇所(件数・表示・選択)がずれるため列挙で持つ
    private enum MenuRow: Int, CaseIterable {
        case home, setting, howToSend, premium

        /// いま出す行。課金が使えないあいだはプレミアムを並べない
        static var visible: [MenuRow] {
            return allCases.filter { $0 != .premium || PremiumStore.isAvailable }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuRow.visible.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: menuOptionCellId)
            ?? UITableViewCell(style: .default, reuseIdentifier: menuOptionCellId)

        // 再利用されたセルにも適用されるよう if cell == nil の外で設定する
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .textPrimary
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedBackgroundView

        switch MenuRow.visible[safe: indexPath.row] {
        case .home:
            cell.textLabel?.text = LocalizeKey.menuHome.localizedString()
        case .setting:
            cell.textLabel?.text = LocalizeKey.menuSetting.localizedString()
        case .premium:
            // 加入済みの人に購入を勧めない
            cell.textLabel?.text = PremiumStore.shared.isPremium
                ? LocalizeKey.menuPremiumActive.localizedString()
                : LocalizeKey.menuPremium.localizedString()
        case .howToSend, .none:
            cell.textLabel?.text = LocalizeKey.menuHowTo.localizedString()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mainNav = sideMenuHost
            ?? parent as? MainNavigationViewController
            ?? navigationController as? MainNavigationViewController

        switch MenuRow.visible[safe: indexPath.row] {
        case .home:
            guard indexPath.row != selectedMenuItem else { return }
            selectedMenuItem = indexPath.row
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let nvc = mainStoryboard.instantiateInitialViewController() as? UINavigationController,
                  let destVC = nvc.viewControllers.first as? MainTabViewController else { return }
            mainNav?.setContentViewController(destVC)
        case .setting:
            guard indexPath.row != selectedMenuItem else { return }
            selectedMenuItem = indexPath.row
            let sb = UIStoryboard(name: "Usage", bundle: nil)
            guard let nvc = sb.instantiateInitialViewController() as? UINavigationController,
                  let destVC = nvc.viewControllers.first as? UsageViewController else { return }
            mainNav?.setContentViewController(destVC)
        case .premium:
            // ペイウォールはモーダル。画面を差し替えると戻り先が無くなる。
            // selectedMenuItem も更新しない(ホーム等の選択状態を保つ)
            // 単一選択なので、この行を選んだ時点で前の行の選択は外れている。
            // 元の画面の選択状態が消えたままにならないよう選び直す
            tableView.selectRow(at: IndexPath(row: selectedMenuItem, section: 0),
                                animated: true, scrollPosition: .none)
            mainNav?.toggleSideMenu()
            guard let host = mainNav else { return }
            if PremiumStore.shared.isPremium {
                PaywallPresenter.presentActiveState(from: host)
            } else {
                PaywallPresenter.present(from: host)
            }
        case .howToSend, .none:
            guard indexPath.row != selectedMenuItem else { return }
            selectedMenuItem = indexPath.row
            mainNav?.setContentViewController(HowToSendViewController())
        }
    }
    
}

private extension Array {
    /// 範囲外でも落ちない添字。行の出し分けで件数と索引がずれたときに守る
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
