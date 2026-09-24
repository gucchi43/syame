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
    /// ロゴの高さ。図を主役にするため控えめにする
    private static let logoHeight: CGFloat = 72
    private weak var heroView: GuideHeroView?
    /// 下段スタックの幅に対する図の幅。
    ///
    /// 図の高さは幅に従属する(正方形のサムネイル3枚 + 余白)ため、幅で高さを決めている。
    /// 0.92 だと iPhone SE で図が見出しに重なった。この画面はロゴ・見出し・ボタン・
    /// 規約文で既に埋まっており、下端固定の下段スタックへ足すと上へ押し上がる。
    private static let guideWidthRatio: CGFloat = 0.62
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        heroView?.stopAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewWillAppear の時点ではまだウインドウに載っておらず、動きが始まらない
        heroView?.startAnimating()
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
        // サブは2行に分ける。「どんなアプリでも」「どんな画像でも」を並べると、
        // 制限の無さが対で伝わる
        subTitleLabel.attributedText =
            (LocalizeKey.topHeadline.localizedString() + "\n\n")
                .withFont(UIFont.scaled(.title3, weight: .bold)).withTextColor(.textPrimary)
            + (LocalizeKey.topSubtitle.localizedString() + "\n")
                .withFont(UIFont.scaled(.footnote, weight: .regular)).withTextColor(.textSecondary)
            + LocalizeKey.topSubtitleSecond.localizedString()
                .withFont(UIFont.scaled(.footnote, weight: .regular)).withTextColor(.textSecondary)
        // 地の塗りは ClayButton が layer 側で持つので backgroundColor は触らない
        // 文字色と影は ClayButton が持つので、ここでは触らない
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
        rebuildLayoutAsVerticalFlow()
    }

    /// 上から下へ流れる1本のレイアウトに組み直す。
    ///
    /// Storyboard 側は縦位置がすべて「画面の中央」基準で、上から下への流れになって
    /// いなかった。ロゴも見出しも centerY に置かれており、図を大きくすると必ず
    /// 見出しに当たる。図を「トーク＋キーボード」に変えて縦に伸びたので、
    /// 中央基準のままでは iPhone SE で成立しない。
    ///
    /// 既存の制約は引き継がない。Storyboard の子を別の親へ移すと、親との制約は
    /// 外れる。中途半端に残すと壊れた状態になるため、ここで全部張り直す。
    private func rebuildLayoutAsVerticalFlow() {
        // 起動直後はまだ自分の画像が無い。ここは紹介用の決まった絵を出す
        let gallery = GuideSampleGallery.photos
        let photos = gallery.isEmpty
            ? GuidePhotoSource.currentSlots(maxPixelSize: TopViewController.thumbnailPixelSize)
            : gallery
        let sent = GuideSampleGallery.sentPhoto ?? photos[0]
        let hero = GuideHeroView(photos: photos, sentPhoto: sent)
        heroView = hero

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = false
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        // 図とボタンは中身の幅いっぱいには広げず、左右に余白を残す
        let column = UIStackView(arrangedSubviews: [logoImage, subTitleLabel, hero, startButton, requestDescription])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = Spacing.xl
        column.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scroll)
        scroll.addSubview(column)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            column.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: Spacing.xl),
            column.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -Spacing.xl),
            column.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: Spacing.l),
            column.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -Spacing.l),
            column.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor,
                                          constant: -Spacing.l * 2),

            // ロゴは小さく。主役は図に譲る
            logoImage.heightAnchor.constraint(equalToConstant: TopViewController.logoHeight),
            hero.widthAnchor.constraint(equalTo: column.widthAnchor,
                                        multiplier: TopViewController.guideWidthRatio),
            startButton.widthAnchor.constraint(equalTo: column.widthAnchor, multiplier: 0.6),
            startButton.heightAnchor.constraint(equalToConstant: 48),
            subTitleLabel.widthAnchor.constraint(equalTo: column.widthAnchor),
            requestDescription.widthAnchor.constraint(equalTo: column.widthAnchor)
        ])

        logoImage.contentMode = .scaleAspectFit
        subTitleLabel.textAlignment = .center
        requestDescription.textAlignment = .center
        column.setCustomSpacing(Spacing.m, after: logoImage)
        column.setCustomSpacing(Spacing.m, after: startButton)
    }
    
    /// ロゴと見出しを淡く出す。
    ///
    /// 以前はロゴを上へ滑らせていたが、その動きは Storyboard の制約
    /// (heightConstraint / leftConstraint)に依存していた。縦の流れへ組み直して
    /// それらを使わなくなったため、位置は動かさず出現だけを残す。
    func animateLogo () {
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
