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
        
        var cell = tableView.dequeueReusableCell(withIdentifier: menuOptionCellId)
        
        if (cell == nil) {
            cell = UITableViewCell(style:.default, reuseIdentifier: menuOptionCellId)
            cell!.backgroundColor = .clear
            cell!.textLabel?.textColor = .white
            let selectedBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: cell!.frame.size.width, height: cell!.frame.size.height))
            selectedBackgroundView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
            cell!.selectedBackgroundView = selectedBackgroundView
        }
        
        switch (indexPath.row) {
        case 0:
            cell!.textLabel?.text = LocalizeKey.menuHome.localizedString()
        case 1:
            cell!.textLabel?.text = LocalizeKey.menuSetting.localizedString()
        case 2:
            cell!.textLabel?.text = LocalizeKey.menuLine.localizedString()
        default:
            cell!.textLabel?.text = LocalizeKey.menuOfficial.localizedString()
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == selectedMenuItem) {
            return
        }
        selectedMenuItem = indexPath.row
        var destViewController : UIViewController
        switch (indexPath.row) {
        case 0:
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main",bundle: nil)
            let nvc = mainStoryboard.instantiateInitialViewController() as! UINavigationController
            destViewController = nvc.viewControllers.first as! MainTabViewController
                    sideMenuController()?.setContentViewController(destViewController)
            break
        case 1:
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Usage",bundle: nil)
            destViewController = mainStoryboard.instantiateViewController(withIdentifier: "UsageViewController") as! UsageViewController
            sideMenuController()?.setContentViewController(destViewController)
            break
        case 2:
            UIApplication.shared.open(URL(string: "http://line.me/ti/p/%40gox9644r")!)
            break
        default:
            UIApplication.shared.open(URL(string: "https://pkbkeyboard.studio.design")!)
            break
        }
    }
    
}
