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

    /// タイトルの最大行数。
    /// 1行だと「まーまーらいおん君による使い方の説明！」のような説明的な題名が
    /// ほとんど読めないまま省略される。
    static let titleLineLimit = 2

    /// タイトルが指定行数を描くのに要る高さ。
    ///
    /// UIFont.lineHeight を行数倍しても足りない。UILabel は行間を足して積むため、
    /// 実測すると1行あたり lineHeight より約1.3pt 高くなる。足りないと折り返しが起きず、
    /// 行数を増やしても1行で省略されたままになるので、ラベルに測らせる。
    private static func titleHeight(lines: Int) -> CGFloat {
        let probe = UILabel()
        probe.font = .scaled(.footnote)
        probe.numberOfLines = lines
        probe.text = Array(repeating: "あ", count: lines).joined(separator: "\n")
        return probe.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                         height: CGFloat.greatestFiniteMagnitude)).height
    }

    /// 画像の下に置く情報エリアの高さ。タイトルの行数ぶんに上下の余白を足したもの。
    /// グリッドの行の高さを決めるため、レイアウト側と共有する。
    ///
    /// 固定値にすると文字サイズを大きくした端末で行が切れるため、実測から求める。
    static var infoHeight: CGFloat {
        return (Spacing.s * 2 + titleHeight(lines: titleLineLimit)).rounded(.up)
    }

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
        titleLabel.numberOfLines = PhotoCollectionViewCell.titleLineLimit
        // 折り返しモードにする。.byTruncatingTail のような切り詰めモードだと
        // numberOfLines を増やしても折り返さず、1行で省略されたままになる。
        // 行数を超えたぶんの末尾の省略記号は UILabel が自分で付ける。
        titleLabel.lineBreakMode = .byWordWrapping
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
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            // 上下とも等号で留めて、ラベルの高さを情報エリアから決める。
            // 上限(lessThanOrEqualTo)にすると高さが UILabel の intrinsicContentSize 任せになり、
            // preferredMaxLayoutWidth が未設定のため1行ぶんに潰れて2行目が出ない。
            // 情報エリアは infoHeight で行数ぶん確保してあるので、ここは割り当てるだけでよい。
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                               constant: -Spacing.s)
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
