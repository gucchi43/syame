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

    @IBOutlet weak var startButton: UIButton!

    /// 開始ボタンと規約文を積んでいる下段のスタック。
    /// 図はこの先頭へ差し込む。Storyboard 側は容器の参照を1つ増やすだけにして、
    /// 中身の組み立てはコードに寄せる
    @IBOutlet weak var bottomStackView: UIStackView!

    @IBOutlet weak var requestDescription: UITextView!

    /// 図に出すサムネイルの最大辺。図の中では数十ptしかない
    private static let thumbnailPixelSize: CGFloat = 240
    /// 下段スタックの幅に対する図の幅。
    ///
    /// 図の高さは幅に従属する(正方形のサムネイル3枚 + 余白)ため、幅で高さを決めている。
    /// 0.92 だと iPhone SE で図が見出しに重なった。この画面はロゴ・見出し・ボタン・
    /// 規約文で既に埋まっており、下端固定の下段スタックへ足すと上へ押し上がる。
    private static let guideWidthRatio: CGFloat = 0.6
    
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
        insertGuideIllustration()
    }

    /// 何をするアプリなのかを絵で伝える。
    ///
    /// ロゴと見出しだけでは伝わらないため、見出しと同じ「キーボードから送る」を図にする。
    /// 図に出るのは利用者自身の保存画像で、まだ無ければ見本で埋まる。
    private func insertGuideIllustration() {
        let photos = GuidePhotoSource.currentSlots(maxPixelSize: TopViewController.thumbnailPixelSize)
        let strip = GuideKeyboardStripView(photos: photos)
        strip.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.insertArrangedSubview(strip, at: 0)
        // スタックは alignment=center なので、幅を与えないと図が潰れる
        strip.widthAnchor.constraint(equalTo: bottomStackView.widthAnchor,
                                     multiplier: TopViewController.guideWidthRatio).isActive = true
        bottomStackView.setCustomSpacing(Spacing.xl, after: strip)
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
        NotificationCenter.default.post(name: .onboardingDidAdvance, object: nil)
        goNextView()
    }
    
    func goNextView () {
        self.dismiss(animated: true, completion: nil)
    }
}
