//
//  EmptySlotCell.swift
//  PhotoKeyboardEx
//
//  まだ埋まっていないマス。くぼんだ面に「+」を置き、押すと追加へ進む。
//

import UIKit
import PhotoKeyboardFramework

final class EmptySlotCell: UICollectionViewCell {

    static let reuseIdentifier = "EmptySlotCell"

    private let surface = ClaySurface(style: .recessed, fill: .bgSurface, cornerRadius: Radius.card)
    private let plusView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        // 見た目だけの「+」画像は VoiceOver から辿れないため、セル自体をボタンとして読ませる
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = LocalizeKey.emptySlotAccessibility.localizedString()

        contentView.backgroundColor = .clear
        surface.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(surface)

        plusView.image = .symbol(Symbol.add, pointSize: 28, weight: .semibold)
        plusView.tintColor = .clayPeach
        plusView.contentMode = .center
        plusView.translatesAutoresizingMaskIntoConstraints = false
        surface.contentView.addSubview(plusView)

        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: contentView.topAnchor),
            surface.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            plusView.centerXAnchor.constraint(equalTo: surface.contentView.centerXAnchor),
            plusView.centerYAnchor.constraint(equalTo: surface.contentView.centerYAnchor)
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
}
