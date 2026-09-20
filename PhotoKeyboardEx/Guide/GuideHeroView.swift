//
//  GuideHeroView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 起動直後に出す、何をするアプリかを一目で伝える図。
///
/// 「キーボードの画像をタップすると、トークにそのまま貼られる」という流れを
/// 上下に並べて示す。App Store の1枚目と同じ構成だが、画像として焼かずに組む。
/// 焼くと文言が日本語のまま英語ロケールに出て、ダークモードにも追従しない。
/// サムネイルには利用者自身の保存画像が入るので、現物ともズレない。
final class GuideHeroView: UIView {

    /// バッジを重ねるのはキーボード側。タップの起点がそこだと分かる
    private let badge = UILabel()

    init(photos: [UIImage], sentPhoto: UIImage) {
        super.init(frame: .zero)
        setupSubviews(photos: photos, sentPhoto: sentPhoto)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews(photos: [UIImage], sentPhoto: UIImage) {
        let chat = GuideChatView(sentPhoto: sentPhoto)
        chat.translatesAutoresizingMaskIntoConstraints = false

        let strip = GuideKeyboardStripView(photos: photos,
                                           titles: GuideSampleGallery.titles,
                                           showsChrome: true)
        strip.translatesAutoresizingMaskIntoConstraints = false

        // 上(トーク)から下(キーボード)へ、貼られた先と貼る元の関係を示す
        let column = UIStackView(arrangedSubviews: [chat, makeBadgeRow(), strip])
        column.axis = .vertical
        column.alignment = .fill
        column.spacing = Spacing.s
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// 「タップして、貼るだけ。」の一行。上下の図の関係を言葉で繋ぐ
    private func makeBadgeRow() -> UIView {
        badge.text = LocalizeKey.heroTapAndPaste.localizedString()
        badge.font = .scaled(.caption1, weight: .bold)
        badge.adjustsFontForContentSizeCategory = true
        badge.textColor = .onAccent
        badge.textAlignment = .center
        badge.numberOfLines = 0
        badge.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.backgroundColor = .accent
        pill.applyCornerRadius(Radius.small)
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(badge)

        let row = UIView()
        row.addSubview(pill)
        pill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: pill.topAnchor, constant: Spacing.s),
            badge.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -Spacing.s),
            badge.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: Spacing.m),
            badge.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -Spacing.m),
            pill.topAnchor.constraint(equalTo: row.topAnchor),
            pill.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            pill.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            pill.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor)
        ])
        return row
    }
}
