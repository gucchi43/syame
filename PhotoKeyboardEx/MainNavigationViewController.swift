//
//  MainNavigationViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/03.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

class MainNavigationViewController: UINavigationController {

    private var menuViewController: UIViewController?
    private var menuContainerView: UIView?
    private var dimmingView: UIView?
    var menuWidth: CGFloat = 180.0
    private(set) var isMenuOpen = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableViewController = MyMenuTableViewController()
        tableViewController.sideMenuHost = self
        menuViewController = tableViewController

        setupSideMenu()
        view.bringSubviewToFront(navigationBar)
    }

    private func setupSideMenu() {
        guard let menuVC = menuViewController else { return }

        let dimming = UIView(frame: view.bounds)
        dimming.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimming.alpha = 0
        dimming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap))
        dimming.addGestureRecognizer(tapGesture)
        view.addSubview(dimming)
        dimmingView = dimming

        let container = UIView(frame: CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.bounds.height))
        container.autoresizingMask = [.flexibleHeight]
        container.backgroundColor = UIColor.bgDark()
        view.addSubview(container)
        menuContainerView = container

        // UINavigationController の children は viewControllers と対応するため、
        // addChild するとメニューがナビゲーションスタックの一部とみなされ全画面表示されてしまう。
        // VC は menuViewController が強参照で保持し、ここではビューだけをコンテナに載せる。
        menuVC.view.frame = container.bounds
        menuVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(menuVC.view)
    }

    @objc private func handleDimmingTap() {
        closeSideMenu()
    }

    func toggleSideMenu() {
        if isMenuOpen {
            closeSideMenu()
        } else {
            openSideMenu()
        }
    }

    func openSideMenu() {
        guard !isMenuOpen else { return }
        isMenuOpen = true
        view.bringSubviewToFront(dimmingView!)
        view.bringSubviewToFront(menuContainerView!)
        view.bringSubviewToFront(navigationBar)

        UIView.animate(withDuration: 0.3) {
            self.menuContainerView?.frame.origin.x = 0
            self.dimmingView?.alpha = 1
        }
    }

    func closeSideMenu() {
        guard isMenuOpen else { return }

        UIView.animate(withDuration: 0.3, animations: {
            self.menuContainerView?.frame.origin.x = -self.menuWidth
            self.dimmingView?.alpha = 0
        }) { _ in
            self.isMenuOpen = false
        }
    }

    func setContentViewController(_ viewController: UIViewController) {
        closeSideMenu()
        setViewControllers([viewController], animated: false)
    }
}
