//
//  GuideStepView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 手順ひとつぶん。番号・文言・図を縦に積む。
///
/// 文言は既存の `Localizable.strings` から引く。図の中に文字を焼くと
/// 英語のときに日本語のままになるため、文字は必ずビューとして置く。
final class GuideStepView: UIView {

    /// 番号バッジの直径
    private static let badgeSize: CGFloat = 24

    init(number: Int, bold: LocalizeKey, normal: LocalizeKey, illustration: UIView) {
        super.init(frame: .zero)
        setupSubviews(number: number, bold: bold, normal: normal, illustration: illustration)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupSubviews(number: Int, bold: LocalizeKey, normal: LocalizeKey, illustration: UIView) {
        let heading = UIStackView(arrangedSubviews: [makeBadge(number: number),
                                                     makeCaption(bold: bold, normal: normal)])
        heading.axis = .horizontal
        heading.alignment = .top
        heading.spacing = Spacing.m

        illustration.translatesAutoresizingMaskIntoConstraints = false

        let column = UIStackView(arrangedSubviews: [heading, illustration])
        column.axis = .vertical
        column.alignment = .fill
        column.spacing = Spacing.m
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeBadge(number: Int) -> UIView {
        let label = UILabel()
        label.text = "\(number)"
        label.font = .scaled(.footnote, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .onAccent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let badge = UIView()
        badge.backgroundColor = .accent
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)
        badge.layer.cornerRadius = GuideStepView.badgeSize / 2
        badge.layer.cornerCurve = .continuous
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: GuideStepView.badgeSize),
            badge.heightAnchor.constraint(equalToConstant: GuideStepView.badgeSize),
            label.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        return badge
    }

    /// 日本語は太字が先、英語は通常文が先。既存の案内画面と同じ組み立て方に揃える
    private func makeCaption(bold: LocalizeKey, normal: LocalizeKey) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .textPrimary
        label.adjustsFontForContentSizeCategory = true
        let boldText = bold.localizedString().withFont(UIFont.scaled(.body, weight: .bold))
        let normalText = normal.localizedString().withFont(UIFont.scaled(.body, weight: .regular))
        label.attributedText = Lang.langRootKey() == "JP" ? boldText + normalText : normalText + boldText
        return label
    }
}
