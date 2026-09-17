//
//  GuideSettingsRowView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 設定アプリの行を模した図。フルアクセスの許可を絵で示す。
///
/// 舞台は設定アプリなので実物を写すことはできない。
/// 「行があって、右のスイッチをオンにする」という構造だけを描く。
/// Apple のロゴや固有の意匠は使わず、色は既存のトークンだけで組む。
final class GuideSettingsRowView: UIView {

    /// スイッチの見た目。実物の UISwitch は操作できてしまうため自前で描く
    private static let switchSize = CGSize(width: 44, height: 26)

    init(title: String) {
        super.init(frame: .zero)
        setupSubviews(title: title)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews(title: String) {
        backgroundColor = .bgSurface
        applyCornerRadius(Radius.small)

        let label = UILabel()
        label.text = title
        label.font = .scaled(.footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let track = UIView()
        track.backgroundColor = .accent
        track.translatesAutoresizingMaskIntoConstraints = false
        track.setContentHuggingPriority(.required, for: .horizontal)
        track.setContentCompressionResistancePriority(.required, for: .horizontal)

        let knob = UIView()
        knob.backgroundColor = .onAccent
        knob.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(knob)

        addSubview(label)
        addSubview(track)

        let size = GuideSettingsRowView.switchSize
        let inset: CGFloat = 2
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),

            track.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: Spacing.m),
            track.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            track.centerYAnchor.constraint(equalTo: centerYAnchor),
            track.widthAnchor.constraint(equalToConstant: size.width),
            track.heightAnchor.constraint(equalToConstant: size.height),

            // オンの状態を描く。つまみは右端に寄る
            knob.trailingAnchor.constraint(equalTo: track.trailingAnchor, constant: -inset),
            knob.centerYAnchor.constraint(equalTo: track.centerYAnchor),
            knob.widthAnchor.constraint(equalToConstant: size.height - inset * 2),
            knob.heightAnchor.constraint(equalToConstant: size.height - inset * 2)
        ])

        track.applyCornerRadius(size.height / 2)
        knob.applyCornerRadius((size.height - inset * 2) / 2)
    }
}
