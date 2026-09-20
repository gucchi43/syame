//
//  HowToSendViewController.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// キーボードから画像を「送る」手順の案内。
///
/// Usage(設定でキーボードを有効にする手順)とは分けている。設定と使い方を1画面に混ぜると
/// 長くなってどちらも読まれないため。キーボードの有効化を初めて検知したときに一度だけ
/// モーダルで出し、以降はサイドメニューから開ける。
final class HowToSendViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let doneButton = AuroraButton()

    /// 図に出すサムネイルの最大辺。図の中では数十ptなので、
    /// フル解像度をデコードするとキーボード拡張と同じくメモリを無駄に食う
    private static let thumbnailPixelSize: CGFloat = 240

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgBase
        view.tintColor = .accent
        configureNavigationItem()
        buildLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 一度見せたら自動表示はしない。閉じ方に関わらず表示した時点で記録する
        if GroupeDefaults.shared.isHowToSendPush() {
            GroupeDefaults.shared.howToSendDone()
            NotificationCenter.default.post(name: .onboardingDidAdvance, object: nil)
        }
    }

    private func configureNavigationItem() {
        let item = UIBarButtonItem(title: nil, style: .plain, target: self,
                                   action: isPresentedModally ? #selector(tapClose) : #selector(tapMenu))
        item.applySymbol(isPresentedModally ? Symbol.close : Symbol.menu)
        navigationItem.leftBarButtonItem = item
    }

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Spacing.xl
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.xl * 2),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Spacing.xl),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Spacing.xl),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.xl * 2),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.xl * 2)
        ])

        let title = UILabel()
        title.numberOfLines = 0
        title.textColor = .textPrimary
        title.adjustsFontForContentSizeCategory = true
        title.attributedText = LocalizeKey.howToTitle.localizedString().withFont(UIFont.scaled(.title3, weight: .bold))
        contentStack.addArrangedSubview(title)

        // 図に出す画像は利用者自身の保存画像。ダミーを焼かないので
        // 「自分のボードの話だ」と伝わり、中身が常に現物と一致する
        // 起動直後の画面と同じ見た目に揃える。案内のたびに絵柄が変わると、
        // 同じ操作の話だと分かりにくい
        let gallery = GuidePhotoSource.currentGallery(maxPixelSize: HowToSendViewController.thumbnailPixelSize)
        let photos = gallery.photos
        let sent = photos.first ?? UIImage()
        let steps: [(LocalizeKey, LocalizeKey, UIView)] = [
            (.howToFirstBoldText, .howToFirstNormalText,
             GuideKeyboardStripView(photos: photos, titles: gallery.titles, showsChrome: true)),
            (.howToSecondBoldText, .howToSecondNormalText, GuideComposerView()),
            (.howToThirdBoldText, .howToThirdNormalText, GuideChatView(sentPhoto: sent))
        ]
        for (index, step) in steps.enumerated() {
            contentStack.addArrangedSubview(GuideStepView(number: index + 1,
                                                          bold: step.0,
                                                          normal: step.1,
                                                          illustration: step.2))
        }

        let description = UILabel()
        description.numberOfLines = 0
        description.textColor = .textSecondary
        description.font = .scaled(.footnote)
        description.adjustsFontForContentSizeCategory = true
        description.text = LocalizeKey.howToDescription.localizedString()
        contentStack.addArrangedSubview(description)

        // 逃げ道はモーダルのときだけ要る。サイドメニューから開いた場合は閉じる先が無い
        if isPresentedModally {
            doneButton.setTitle(LocalizeKey.howToDone.localizedString(), for: .normal)
            doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
            doneButton.applyCornerRadius(Radius.small)
            doneButton.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
            doneButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
            contentStack.setCustomSpacing(Spacing.xl * 2, after: description)
            contentStack.addArrangedSubview(doneButton)
        }
    }

    @objc private func tapClose() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func tapMenu() {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
}
