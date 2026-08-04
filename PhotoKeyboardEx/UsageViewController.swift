//
//  UsageViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/21.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

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
        if GroupeDefaults.shared.isUsagePush() {
            self.setOfficialPhoto()
            GroupeDefaults.shared.usageDone()
        }
    }
    
    func commonInit() {
        scrollView.backgroundColor = .bgBase
        baseView.backgroundColor = .bgBase
        firstLabel.textColor = .textPrimary
        firstLabel.adjustsFontForContentSizeCategory = true
        secondLabel.textColor = .textPrimary
        secondLabel.adjustsFontForContentSizeCategory = true
        thirdLabel.textColor = .textPrimary
        thirdLabel.adjustsFontForContentSizeCategory = true
        fourthLabel.textColor = .textPrimary   
        fourthLabel.adjustsFontForContentSizeCategory = true
        navBarButton.applySymbol(Symbol.menu)
        nextButton.setTitle(LocalizeKey.settingDone.localizedString(), for: .normal)
        nextButton.setTitleColor(.onAccent, for: .normal)
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nextButton.backgroundColor = .accent
        nextButton.applyCornerRadius(Radius.small)
        subLabel.textColor = .textPrimary
        subLabel.adjustsFontForContentSizeCategory = true
    }
    
    func setText() {
        if Lang.langRootKey() == "JP" {
            firstLabel.attributedText = LocalizeKey.settingTitle.localizedString().withFont(UIFont.scaled(.title3, weight: .bold))
            secondLabel.attributedText = LocalizeKey.settingFirstBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold)) + LocalizeKey.settingFirstNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular))
            thirdLabel.attributedText = LocalizeKey.settingSecondBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold)) + LocalizeKey.settingSecondNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular))
            fourthLabel.attributedText = LocalizeKey.settingThirdBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold)) + LocalizeKey.settingThirdNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular))
            subLabel.text = LocalizeKey.settingDiscription.localizedString()
        } else {
            firstLabel.attributedText = LocalizeKey.settingTitle.localizedString().withFont(UIFont.scaled(.title3, weight: .bold))
            secondLabel.attributedText = LocalizeKey.settingFirstNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular)) +  LocalizeKey.settingFirstBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold))
            thirdLabel.attributedText = LocalizeKey.settingSecondNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular)) +  LocalizeKey.settingSecondBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold))
            fourthLabel.attributedText = LocalizeKey.settingThirdNormalText.localizedString().withFont(UIFont.scaled(.footnote, weight: .regular)) + LocalizeKey.settingThirdBoaldText.localizedString().withFont(UIFont.scaled(.footnote, weight: .bold))
            subLabel.text = LocalizeKey.settingDiscription.localizedString()
        }
    }
    
    func setOfficialPhoto() {
        // Realmにsaveする
        guard let photo = makeOfficialPhoto() else { return }
        RealmManager.shared.save(data: photo, success: {() in
        }) { (error) in
            print(error)
        }
    }

    @IBAction func tapNavBarButton(_ sender: Any) {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            if GroupeDefaults.shared.isWelcomePush() {
                goWelcomeView()
            }
        }
    }
    
    func goWelcomeView() {
        let sb: UIStoryboard = UIStoryboard(name: "Welcome",bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
        self.show(vc, sender: nil)
    }
}
