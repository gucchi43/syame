//
//  GuideKeyboardStripView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 手順①「キーボードで画像をタップ」の図。
///
/// 実物のキーボードを1pxまで再現するのが目的ではない。伝えたいのは
/// 「キーボードの中に自分の画像が並ぶ」という構造だけなので、簡略化した図として組む。
/// 色は既存のトークン(`keyboardBase` / `keyboardSurface`)をそのまま使い、
/// ダークモードには自動で追従させる。
final class GuideKeyboardStripView: UIView {

    /// サムネイルの縦横比。実物のセルと同じく正方形にする
    private static let thumbnailAspect: CGFloat = 1.0

    init(photos: [UIImage]) {
        super.init(frame: .zero)
        setupSubviews(photos: photos)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupSubviews(photos: [UIImage]) {
        backgroundColor = .keyboardBase
        applyCornerRadius(Radius.card)
        clipsToBounds = true

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = Spacing.s
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m)
        ])

        for (index, photo) in photos.enumerated() {
            // 印は先頭の1枚だけ。全部に付けると「どれをタップしたか」が読めなくなる
            row.addArrangedSubview(makeThumbnail(photo, isCopied: index == 0))
        }
    }

    /// タップした1枚に重ねる「コピー」の印。
    /// これが無いと、タップが何を起こすのかが図から読み取れず次の手順へ繋がらない
    private func makeCopyBadge() -> UIView {
        let label = UILabel()
        label.text = LocalizeKey.guideCopyBadge.localizedString()
        label.font = .scaled(.caption2, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .onAccent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let badge = UIView()
        badge.backgroundColor = .accent
        badge.applyCornerRadius(Radius.small / 2)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: Spacing.grid),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -Spacing.grid),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: Spacing.s),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -Spacing.s)
        ])
        return badge
    }

    private func makeThumbnail(_ photo: UIImage, isCopied: Bool) -> UIView {
        let imageView = UIImageView(image: photo)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .keyboardSurface
        imageView.applyCornerRadius(Radius.small)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                          multiplier: GuideKeyboardStripView.thumbnailAspect).isActive = true
        guard isCopied else { return imageView }

        // 印は角丸で切り取られないよう、画像の外側の容器に載せる
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)

        let badge = makeCopyBadge()
        container.addSubview(badge)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}
