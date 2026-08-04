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
        tableView.contentInset = UIEdgeInsets(top: 64.0, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.scrollsToTop = false
        clearsSelectionOnViewWillAppear = false
        tableView.selectRow(at: IndexPath(row: selectedMenuItem, section: 0), animated: false, scrollPosition: .middle)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
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

        switch (indexPath.row) {
        case 0:
            cell.textLabel?.text = LocalizeKey.menuHome.localizedString()
        case 1:
            cell.textLabel?.text = LocalizeKey.menuSetting.localizedString()
        case 2:
            cell.textLabel?.text = LocalizeKey.menuLine.localizedString()
        default:
            cell.textLabel?.text = LocalizeKey.menuOfficial.localizedString()
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

        switch (indexPath.row) {
        case 0:
            guard indexPath.row != selectedMenuItem else { return }
            selectedMenuItem = indexPath.row
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let nvc = mainStoryboard.instantiateInitialViewController() as? UINavigationController,
                  let destVC = nvc.viewControllers.first as? MainTabViewController else { return }
            mainNav?.setContentViewController(destVC)
        case 1:
            guard indexPath.row != selectedMenuItem else { return }
            selectedMenuItem = indexPath.row
            let sb = UIStoryboard(name: "Usage", bundle: nil)
            guard let nvc = sb.instantiateInitialViewController() as? UINavigationController,
                  let destVC = nvc.viewControllers.first as? UsageViewController else { return }
            mainNav?.setContentViewController(destVC)
        default:
            // 外部リンクは画面を差し替えないので選択状態は変えず、メニューは閉じる
            tableView.selectRow(at: IndexPath(row: selectedMenuItem, section: 0), animated: false, scrollPosition: .none)
            mainNav?.closeSideMenu()
            if indexPath.row == 2 {
                UIApplication.shared.openOfficialLINE()
            } else if let url = URL(string: "https://pkbkeyboard.studio.design") {
                UIApplication.shared.open(url)
            }
        }
    }
    
}
