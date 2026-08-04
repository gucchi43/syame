 //
//  WelcomeViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/23.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
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
        
        print("viewWillAppear welcomeViewController")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear welcomeViewController")
    }
    
    func commonInit() {
        self.view.backgroundColor = .bgBase
        titleLabel.textColor = .textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        firstLabel.textColor = .textPrimary
        firstLabel.adjustsFontForContentSizeCategory = true
        secondLabel.textColor = .textPrimary
        secondLabel.adjustsFontForContentSizeCategory = true
        thirdLabel.textColor = .textPrimary
        thirdLabel.adjustsFontForContentSizeCategory = true
        fourthLabel.textColor = .textPrimary
        fourthLabel.adjustsFontForContentSizeCategory = true
        explainLabel.textColor = .textPrimary
        explainLabel.adjustsFontForContentSizeCategory = true
        nextButton.setTitleColor(.onAccent, for: .normal)
        nextButton.applyCornerRadius(Radius.small)
        nextButton.backgroundColor = .accent
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nextButton.setTitle(LocalizeKey.welcomeDone.localizedString(), for: .normal)
    }
    
    func settext() {
        skipButton.title = LocalizeKey.welcomeSkip.localizedString()
        titleLabel.attributedText = LocalizeKey.welcomeTitle.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title1, weight: .bold))
        firstLabel.attributedText = LocalizeKey.welcomeFirst1.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeFirst2.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeFirst3.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
        secondLabel.attributedText = LocalizeKey.welcomeSecond1.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeSecond2.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeSecond3.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
        thirdLabel.attributedText = LocalizeKey.welcomeThird1.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeThird2.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
            + LocalizeKey.welcomeThird3.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))
        fourthLabel.attributedText =  LocalizeKey.welcomeFourth.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title2, weight: .bold))

        explainLabel.attributedText = LocalizeKey.welcomeDiscriptionFirst.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.body, weight: .regular)) + LocalizeKey.welcomeDiscriptionSecond.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.title3, weight: .bold)) + LocalizeKey.welcomeDiscriptionThird.localizedString().withTextColor(.textPrimary).withFont(UIFont.scaled(.body, weight: .regular))
        
        explainLabel.numberOfLines = 0
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        UIApplication.shared.openOfficialLINE { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            if GroupeDefaults.shared.isWelcomePush() {
                GroupeDefaults.shared.welcomeDone()
            }
        }
    }
    
    
    @IBAction func tapSkipButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        if GroupeDefaults.shared.isWelcomePush() {
            GroupeDefaults.shared.welcomeDone()
        }
    }
 }
