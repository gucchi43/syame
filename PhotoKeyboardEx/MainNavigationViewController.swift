//
//  MainNavigationViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/03.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import ENSwiftSideMenu

class MainNavigationViewController: ENSideMenuNavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a table view controller
        let tableViewController = MyMenuTableViewController()
        
        // Create side menu
        sideMenu = ENSideMenu(sourceView: view, menuViewController: tableViewController, menuPosition:.left)
        
        // Set a delegate
        sideMenu?.delegate = self
        
        // Configure side menu
        sideMenu?.menuWidth = 180.0
        
        // Show navigation bar above side menu
        view.bringSubviewToFront(navigationBar)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapMainTabButton(_ sender: Any) {
    }
}

extension MainNavigationViewController: ENSideMenuDelegate {
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        return true
    }
}

