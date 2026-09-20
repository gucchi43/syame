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

    /// 実物に寄せるかどうか。
    /// 起動直後の画面では上のツールバーとセルの題名まで描いて本物に近づける。
    /// 使い方の手順では、構造だけ伝わればよいので簡略のままにする。
    private let showsChrome: Bool

    init(photos: [UIImage], titles: [String] = [], showsChrome: Bool = false) {
        self.showsChrome = showsChrome
        self.titles = titles
        super.init(frame: .zero)
        setupSubviews(photos: photos)
    }

    private let titles: [String]

    /// タップの対象になっているセルと、その上のコピーの印。動きを付けるために持つ
    private(set) weak var tappedCell: UIView?
    private(set) weak var copyBadge: UIView?

    required init?(coder: NSCoder) {
        self.showsChrome = false
        self.titles = []
        super.init(coder: coder)
    }

    private func setupSubviews(photos: [UIImage]) {
        backgroundColor = .keyboardBase
        applyCornerRadius(Radius.card)
        clipsToBounds = true

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = showsChrome ? 1 : Spacing.s
        row.translatesAutoresizingMaskIntoConstraints = false

        for (index, photo) in photos.enumerated() {
            // 印は先頭の1枚だけ。全部に付けると「どれをタップしたか」が読めなくなる
            row.addArrangedSubview(makeCell(photo,
                                            title: index < titles.count ? titles[index] : nil,
                                            isCopied: index == 0))
        }

        let column = UIStackView(arrangedSubviews: showsChrome ? [makeToolbar(), row] : [row])
        column.axis = .vertical
        column.spacing = Spacing.s
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        let inset = showsChrome ? Spacing.s : Spacing.m
        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
    }

    /// 実物のキーボード上部。左にホームと列数の切り替え、右に文字入力への切り替え
    private func makeToolbar() -> UIView {
        func icon(_ name: String) -> UIImageView {
            let view = UIImageView(image: .symbol(name, textStyle: .footnote, weight: .semibold))
            view.tintColor = .accent
            view.setContentHuggingPriority(.required, for: .horizontal)
            return view
        }
        let text = UILabel()
        text.text = LocalizeKey.keyboardTextMode.localizedString()
        text.font = .scaled(.footnote, weight: .bold)
        text.adjustsFontForContentSizeCategory = true
        text.textColor = .accent

        let bar = UIStackView(arrangedSubviews: [icon(Symbol.home), icon(Symbol.gridDense),
                                                 UIView(), text])
        bar.axis = .horizontal
        bar.alignment = .center
        bar.spacing = Spacing.s
        return bar
    }

    /// セル1つ。実物は画像の下に題名が付く
    private func makeCell(_ photo: UIImage, title: String?, isCopied: Bool) -> UIView {
        let thumbnail = makeThumbnail(photo, isCopied: isCopied)
        guard showsChrome, let title = title else { return thumbnail }

        let label = UILabel()
        label.text = title
        label.font = .scaled(.caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        label.lineBreakMode = .byTruncatingTail

        let cell = UIStackView(arrangedSubviews: [thumbnail, label])
        cell.axis = .vertical
        cell.spacing = Spacing.grid
        cell.isLayoutMarginsRelativeArrangement = true
        cell.layoutMargins = UIEdgeInsets(top: 0, left: Spacing.grid,
                                          bottom: Spacing.grid, right: Spacing.grid)
        cell.backgroundColor = .keyboardSurface
        return cell
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
        imageView.applyCornerRadius(showsChrome ? Spacing.grid : Radius.small)
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
        copyBadge = badge
        tappedCell = container

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
