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

        let steps: [(String, LocalizeKey, LocalizeKey)] = [
            (Symbol.stepTap, .howToFirstBoldText, .howToFirstNormalText),
            (Symbol.stepClipboard, .howToSecondBoldText, .howToSecondNormalText),
            (Symbol.stepSend, .howToThirdBoldText, .howToThirdNormalText)
        ]
        for (symbol, bold, normal) in steps {
            contentStack.addArrangedSubview(makeStepRow(symbol: symbol, bold: bold, normal: normal))
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

    /// Usage 画面と同じく、日本語は太字が先、英語は通常文が先
    private func makeStepRow(symbol: String, bold: LocalizeKey, normal: LocalizeKey) -> UIView {
        let icon = UIImageView(image: UIImage.symbol(symbol, pointSize: 26))
        icon.tintColor = .accent
        icon.contentMode = .center
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .textPrimary
        label.adjustsFontForContentSizeCategory = true
        let boldText = bold.localizedString().withFont(UIFont.scaled(.body, weight: .bold))
        let normalText = normal.localizedString().withFont(UIFont.scaled(.body, weight: .regular))
        label.attributedText = Lang.langRootKey() == "JP" ? boldText + normalText : normalText + boldText

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Spacing.m
        return row
    }

    @objc private func tapClose() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func tapMenu() {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
}
