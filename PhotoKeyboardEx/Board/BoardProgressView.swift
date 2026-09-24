//
//  BoardProgressView.swift
//  PhotoKeyboardEx
//
//  マイボードの上に出す「3 / 8」のピル。上限まで埋まると「コンプリート」に変わる。
//

import UIKit
import PhotoKeyboardFramework

final class BoardProgressView: UICollectionReusableView {

    static let reuseIdentifier = "BoardProgressView"
    static let elementKind = "BoardProgressHeader"

    let label = UILabel()
    private let pill = ClaySurface(style: .raised, fill: .clayMint, cornerRadius: Radius.small)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        pill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pill)

        label.applyTextStyle(.subheadline, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.contentView.addSubview(label)

        // ClaySurface.contentView は layoutSubviews で body.bounds に合わせて frame を
        // 手動で流し込んでおり、Auto Layout には参加しない。そのため contentView 側の
        // アンカーに幅を委ねると解決できず、pill の幅が 0 に潰れる。
        // label の幅から pill 自体の幅が決まるよう、pill 自身のアンカーに直接つなぐ
        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s),
            pill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s),
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: Spacing.s),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -Spacing.s),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: Spacing.xl),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -Spacing.xl)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pill.cornerRadius = pill.bounds.height / 2
    }

    func apply(filled: Int, limit: Int) {
        if filled >= limit {
            label.text = LocalizeKey.boardComplete.localizedString()
        } else {
            label.text = LocalizeKey.boardProgress.localizedString(filled, limit)
        }
    }
}
