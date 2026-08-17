//
//  TopViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/17.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

class TopViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var logoImage: UIImageView!

    @IBOutlet weak var animateBaseView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!

    @IBOutlet weak var subTitleLabel: UILabel!

    @IBOutlet weak var registerStack: UIStackView!
    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var requestDescription: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateLogo()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        return false
    }

    func initLayout() {
        // 旧ブランドの紫背景がストーリーボードに残っているため、ここで現行の配色に上書きする
        view.backgroundColor = .bgBase
        logoImage.alpha = 0.0
        subTitleLabel.alpha = 0.0
        // 何ができるアプリなのかを最初に伝える。
        // 以前はロゴと開始ボタンだけで、説明が一言も無かった。
        subTitleLabel.numberOfLines = 0
        subTitleLabel.textAlignment = .center
        subTitleLabel.adjustsFontForContentSizeCategory = true
        subTitleLabel.attributedText =
            (LocalizeKey.topHeadline.localizedString() + "\n\n")
                .withFont(UIFont.scaled(.title3, weight: .bold)).withTextColor(.textPrimary)
            + LocalizeKey.topSubtitle.localizedString()
                .withFont(UIFont.scaled(.footnote, weight: .regular)).withTextColor(.textSecondary)
        // 地の塗りは AuroraButton が layer 側で持つので backgroundColor は触らない
        // 文字色と影は AuroraButton が持つので、ここでは触らない
        startButton.applyCornerRadius(Radius.small)
        startButton.titleLabel?.adjustsFontSizeToFitWidth = true
        startButton.setTitle(LocalizeKey.topStart.localizedString(), for: .normal)

        let firstAtr = LocalizeKey.topRequestFirst.localizedString()
        let secondAtr = LocalizeKey.topRequestSecond.localizedString()
        let thirdAtr = LocalizeKey.topRequestThird.localizedString()
        let fourthAtr = LocalizeKey.topRequestFourth.localizedString()
        let fifthAtr = LocalizeKey.topRequestFifth.localizedString()
        let fullString = firstAtr + secondAtr + thirdAtr + fourthAtr + fifthAtr

        let attributedString = NSMutableAttributedString(string: fullString)
        let fullRange = NSRange(location: 0, length: (fullString as NSString).length)
        attributedString.addAttribute(.foregroundColor, value: UIColor.textPrimary, range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.scaled(.footnote, weight: .regular), range: fullRange)

        let nstring = fullString as NSString
        if let termsUrl = URL(string: "https://pkbkeyboard.studio.design/terms") {
            let termsRange = nstring.range(of: secondAtr)
            attributedString.addAttribute(.link, value: termsUrl, range: termsRange)
        }
        if let privacyUrl = URL(string: "https://pkbkeyboard.studio.design/privacy") {
            let privacyRange = nstring.range(of: fourthAtr)
            attributedString.addAttribute(.link, value: privacyUrl, range: privacyRange)
        }

        requestDescription.attributedText = attributedString
        requestDescription.linkTextAttributes = [.foregroundColor: UIColor.accent]
        requestDescription.isEditable = false
        requestDescription.isScrollEnabled = false
        requestDescription.backgroundColor = .clear
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
