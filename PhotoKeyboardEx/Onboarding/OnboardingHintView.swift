//
//  OnboardingHintView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// ボードの上に常設する「次にやること」の一行。
///
/// 案内をモーダルだけに頼ると、閉じた瞬間に手がかりが消える。
/// とくに1枚も保存しない利用者は、以前はキーボードの有効化を知る機会が無かった。
final class OnboardingHintView: UIControl {

    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews() {
        backgroundColor = .accentSoft
        applyCornerRadius(Radius.small)

        label.numberOfLines = 0
        label.textColor = .textPrimary
        label.font = .scaled(.footnote, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: .symbol(Symbol.next, textStyle: .footnote, weight: .bold))
        chevron.tintColor = .accent
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        // 文字とシェブロンはタップを拾わせない。押せるのは行そのもの
        label.isUserInteractionEnabled = false
        chevron.isUserInteractionEnabled = false
        addSubview(label)
        addSubview(chevron)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            chevron.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: Spacing.s),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    /// 出す手順を与える。案内が要らない手順なら自分を隠す
    func apply(step: OnboardingStep) {
        guard let key = step.hintKey else {
            isHidden = true
            return
        }
        isHidden = false
        label.text = key.localizedString()
        accessibilityLabel = label.text
    }
}
