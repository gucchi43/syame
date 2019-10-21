//
//  TopViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/17.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import SwiftyAttributes
import TTTAttributedLabel

class TopViewController: UIViewController, TTTAttributedLabelDelegate {

    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var animateBaseView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var registerStack: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var requestDescription: TTTAttributedLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateLogo()
    }
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func initLayout() {
        logoImage.alpha = 0.0
        subTitleLabel.alpha = 0.0
        subTitleLabel.text = LocalizeKey.topSubtitle.localizedString()
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 8.0
        startButton.backgroundColor = .acGreen()
        startButton.titleLabel?.adjustsFontSizeToFitWidth = true
        startButton.setTitle(LocalizeKey.topStart.localizedString(), for: .normal)
        let firstAtr = LocalizeKey.topRequestFirst.localizedString()
        let secondAtr = LocalizeKey.topRequestSecond.localizedString()
        let thirdAtr = LocalizeKey.topRequestThird.localizedString()
        let fourthAtr = LocalizeKey.topRequestFourth.localizedString()
        let fifthAtr = LocalizeKey.topRequestFifth.localizedString()
        let string = firstAtr + secondAtr + thirdAtr + fourthAtr + fifthAtr
        requestDescription.text = string
        requestDescription.linkAttributes = [NSAttributedString.Key.foregroundColor.rawValue: UIColor.acGreen().cgColor]
        requestDescription.activeLinkAttributes = [NSAttributedString.Key.foregroundColor.rawValue: UIColor.acGreen().cgColor]
        let nstring = string as NSString
        let firstRange = nstring.range(of: secondAtr)
        let firstUrl = URL(string: "https://pkbkeyboard.studio.design/terms")
        requestDescription.addLink(to: firstUrl, with: firstRange)
        let secondRange = nstring.range(of: fourthAtr)
        let secondUrl = URL(string: "https://pkbkeyboard.studio.design/privacy")
        requestDescription.addLink(to: secondUrl, with: secondRange)
        requestDescription.delegate = self
    }
    
    func animateLogo () {
        
        self.heightConstraint.constant = -160
        self.leftConstraint.constant = 80
        UIView.animate(withDuration: 1.0, animations: {
            self.animateBaseView.layoutIfNeeded()
            self.logoImage.alpha = 1.0
        }) { (_) in
            self.subTitleLabel.alpha = 1.0
        }
    }
    
    
    @IBAction func tapStartButton(_ sender: Any) {
        //このTopを開くか判断するフラグを切り替える
        GroupeDefaults.shared.registerDone()
        goNextView()
    }
    
    func goNextView () {
        self.dismiss(animated: true, completion: nil)
    }
}
