//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

/// マイボード一覧のセル。
///
/// xib をやめてコードで組んでいる。画像・タイトル・メニューという単純な構成に対して
/// xib 側の制約が噛み合わず、タイトルが表示されない状態になっていたため。
final class PhotoCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "PhotoCollectionViewCell"

    /// 画像の下に置く情報エリアの高さ。タイトル1行ぶん。
    /// グリッドの行の高さを決めるため、レイアウト側と共有する。
    static let infoHeight: CGFloat = 40

    let photoImageView = UIImageView()
    let titleLabel = UILabel()
    let menuButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        titleLabel.text = nil
        menuButton.menu = nil
    }

    private func setupSubviews() {
        contentView.backgroundColor = .bgSurface
        contentView.applyCornerRadius(Radius.card)

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = .bgBase
        photoImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.applyTextStyle(.footnote)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 画像の上に重なるため、写真の明暗に関わらず読める必要がある。
        // 面の下地を敷いて、その上に暗いアイコンを置く。
        menuButton.setImage(.symbol(Symbol.more, textStyle: .footnote, weight: .semibold), for: .normal)
        menuButton.tintColor = .accent
        menuButton.backgroundColor = .bgSurface
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(photoImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(menuButton)

        let menuSize: CGFloat = 28
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // 画像は正方形。可変にすると同じ行の2つのセルで高さが揃わない
            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor),

            menuButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.s),
            menuButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.s),
            menuButton.widthAnchor.constraint(equalToConstant: menuSize),
            menuButton.heightAnchor.constraint(equalToConstant: menuSize),

            titleLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: Spacing.s),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m)
        ])

        menuButton.layer.cornerRadius = menuSize / 2
        menuButton.layer.cornerCurve = .continuous
        menuButton.clipsToBounds = true
    }

    /// - Parameter menu: 3点リーダーから開くメニュー。呼び出し側が組み立てる
    func configure(photo: RealmPhoto, menu: UIMenu?) {
        photoImageView.image = photo.image
        titleLabel.text = photo.text
        menuButton.menu = menu
    }
}
