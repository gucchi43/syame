//
//  UsageViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/21.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor
import FontAwesome_swift
import ENSwiftSideMenu
import SwiftyAttributes

class UsageViewController: UIViewController {

    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var thirdImageView: UIImageView!
    @IBOutlet weak var fourthImageView: UIImageView!
    @IBOutlet weak var navBarButton: UIBarButtonItem!
    
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        setText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func commonInit() {
        scrollView.backgroundColor = .bgDark()
        baseView.backgroundColor = .bgDark()
        firstLabel.textColor = .white
        secondLabel.textColor = .white
        thirdLabel.textColor = .white
        fourthLabel.textColor = .white   
        navBarButton.title = String.fontAwesomeIcon(name: .bars)
        navBarButton.setTitleTextAttributes([.font: UIFont.fontAwesome(ofSize: 24, style: .solid)], for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = .acGreen()
        nextButton.layer.cornerRadius = 8.0
        subLabel.textColor = .white
    }
    
    func setText() {
        secondLabel.attributedText = "PKBの設定".withFont(Font.systemFont(ofSize: 24, weight: .bold))
        secondLabel.attributedText = " [キーボード] ".withFont(Font.systemFont(ofSize: 14, weight: .bold)) + "をタップする".withFont(Font.systemFont(ofSize: 14, weight: .regular))
        thirdLabel.attributedText = " PKB ".withFont(Font.systemFont(ofSize: 14, weight: .bold)) + "を有効にする".withFont(Font.systemFont(ofSize: 14, weight: .regular))
        fourthLabel.attributedText = " [フルアクセスを許可] ".withFont(Font.systemFont(ofSize: 14, weight: .bold)) + "をオンにする".withFont(Font.systemFont(ofSize: 14, weight: .regular))
        subLabel.text = "これでPKBをキーボードから使えるようになります。\nもし設定方法がわからない場合は「LINEでお問い合わせ」からご連絡ください。"
    }

    @IBAction func tapNavBarButton(_ sender: Any) {
        toggleSideMenuView()
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            goWelcomeView()
        }
    }
    
    func goWelcomeView() {
        let sb: UIStoryboard = UIStoryboard(name: "Welcome",bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
        self.show(vc, sender: nil)
    }
}
