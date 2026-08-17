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
        // 見本画像の投入は起動時に移した。ここでは案内済みの記録だけ行う
        if GroupeDefaults.shared.isUsagePush() {
            GroupeDefaults.shared.usageDone()
        }
    }
    
    func commonInit() {
        view.backgroundColor = .bgBase
        // 手順のアイコン(テンプレート画像)を旧テーマの緑からモノトーンに揃える
        view.tintColor = .accent
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
        addLaterButtonIfPresentedModally()
        // 文字色と影は AuroraButton が持つ
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
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
    
    /// モーダルで出したときだけ「あとで」を足す。
    ///
    /// 逃げ道が無いと、フルアクセスを決めきれない人はアプリごと閉じてしまう。
    /// アプリ内で完結するコピー導線ができたので、後回しにしても体験は壊れない。
    /// サイドメニューから開いた場合は閉じる先が無いため出さない。
    private func addLaterButtonIfPresentedModally() {
        let isModal = presentingViewController != nil || navigationController?.presentingViewController != nil
        guard isModal, let container = nextButton.superview else { return }

        let later = UIButton(type: .system)
        later.setTitle(LocalizeKey.settingLater.localizedString(), for: .normal)
        later.setTitleColor(.textSecondary, for: .normal)
        later.titleLabel?.font = .scaled(.footnote)
        later.titleLabel?.adjustsFontForContentSizeCategory = true
        later.addTarget(self, action: #selector(tapLaterButton), for: .touchUpInside)
        later.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(later)
        NSLayoutConstraint.activate([
            later.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: Spacing.m),
            later.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            later.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    @objc private func tapLaterButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapNavBarButton(_ sender: Any) {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        guard UIApplication.shared.canOpenURL(settingsUrl) else { return }
        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        // 設定アプリへ移るので、戻ってきたときに案内が残らないよう閉じる
        dismiss(animated: true, completion: nil)
    }
    
}
