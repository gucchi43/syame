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

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s),
            pill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s),
            label.topAnchor.constraint(equalTo: pill.contentView.topAnchor, constant: Spacing.s),
            label.bottomAnchor.constraint(equalTo: pill.contentView.bottomAnchor, constant: -Spacing.s),
            label.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: Spacing.xl),
            label.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -Spacing.xl)
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
