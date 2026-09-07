//
//  GuideComposerView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 手順②「入力欄を長押しして『ペースト』」の図。
///
/// 貼り先は他社アプリの入力欄なので、実物を写すことも再現することもできない。
/// 「入力欄があって、その上にペーストの選択肢が出る」という構造だけを描く。
/// 特定のアプリを思わせる意匠(アイコン・送信ボタン・配色)は載せない。
final class GuideComposerView: UIView {

    /// 入力欄の高さ。実物と揃える必要はなく、吹き出しとの対比が付けばよい
    private static let barHeight: CGFloat = 44

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupSubviews() {
        backgroundColor = .bgBase
        applyCornerRadius(Radius.card)
        clipsToBounds = true

        let bar = UIView()
        bar.backgroundColor = .bgSurface
        bar.applyCornerRadius(Radius.small)
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar)

        let bubble = makePasteBubble()
        addSubview(bubble)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            bar.heightAnchor.constraint(equalToConstant: GuideComposerView.barHeight),

            // 長押しで入力欄の上に出る、という位置関係をそのまま図にする
            bubble.centerXAnchor.constraint(equalTo: centerXAnchor),
            bubble.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -Spacing.s),
            bubble.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Spacing.m)
        ])
    }

    private func makePasteBubble() -> UIView {
        let label = UILabel()
        label.text = LocalizeKey.guidePasteBadge.localizedString()
        label.font = .scaled(.footnote, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .onAccent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let bubble = UIView()
        bubble.backgroundColor = .accent
        bubble.applyCornerRadius(Radius.small / 2)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: Spacing.s),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -Spacing.s),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: Spacing.l),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -Spacing.l)
        ])
        return bubble
    }
}
