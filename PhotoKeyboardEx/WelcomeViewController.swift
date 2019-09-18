 //
//  WelcomeViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/23.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor
import SwiftyAttributes
import PhotoKeyboardFramework

class WelcomeViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    
    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var skipButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        settext()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if GroupeDefaults.shared.isWelcomePush() {
            GroupeDefaults.shared.welcomeDone()
        }
//        if self.presentingViewController != nil {
//            // モーダルされたときの処理
//            nextButton.isHidden = false
//        } else {
//            nextButton.isHidden = true
//        }
    }
    
    func commonInit() {
        self.view.backgroundColor = .bgDark()
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        firstLabel.textColor = .white
        secondLabel.textColor = .white
        thirdLabel.textColor = .white
        fourthLabel.textColor = .white
        explainLabel.textColor = .white
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 8.0
        nextButton.backgroundColor = .acGreen()
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nextButton.setTitle(LocalizeKey.welcomeDone.localizedString(), for: .normal)
    }
    
    func settext() {
        skipButton.title = LocalizeKey.welcomeSkip.localizedString()
        titleLabel.attributedText = LocalizeKey.welcomeTitle.localizedString().withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 40.0, weight: .bold))
        firstLabel.attributedText = LocalizeKey.welcomeFirst1.localizedString().withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeFirst2.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeFirst3.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        secondLabel.attributedText = LocalizeKey.welcomeSecond1.localizedString().withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeSecond2.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeSecond3.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        thirdLabel.attributedText = LocalizeKey.welcomeThird1.localizedString().withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeThird2.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
            + LocalizeKey.welcomeThird3.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        fourthLabel.attributedText =  LocalizeKey.welcomeFourth.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        
        fourthLabel.attributedText =  LocalizeKey.welcomeFourth.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        explainLabel.attributedText = LocalizeKey.welcomeDiscriptionFirst.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 16.0, weight: .regular)) + LocalizeKey.welcomeDiscriptionSecond.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 24.0, weight: .bold)) + LocalizeKey.welcomeDiscriptionThird.localizedString().withTextColor(.white).withFont(Font.systemFont(ofSize: 16.0, weight: .regular))
        
//        explainLabel.text = LocalizeKey.welcomeDiscription.localizedString()
        explainLabel.numberOfLines = 0
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        UIApplication.shared.open(URL(string: "http://line.me/ti/p/%40gox9644r")!)
        UIApplication.shared.open(URL(string: "http://line.me/ti/p/%40gox9644r")!, options: [:]) { (done) in
            self.dismiss(animated: true, completion: nil)
        }
//        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func tapSkipButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
 }
