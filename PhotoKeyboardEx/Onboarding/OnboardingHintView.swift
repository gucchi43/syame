//
//  OnboardingHintView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// ボードの上に常設する「次にやること」の一行。黄色い付箋として貼ってある体裁にする。
///
/// 案内をモーダルだけに頼ると、閉じた瞬間に手がかりが消える。
/// とくに1枚も保存しない利用者は、以前はキーボードの有効化を知る機会が無かった。
final class OnboardingHintView: UIControl {

    private let label = UILabel()
    /// 右下の折り返し。付箋の角がめくれて見えるようにする三角形
    private let foldLayer = CAShapeLayer()
    /// 折り返しの一辺の長さ
    private static let foldSize: CGFloat = 16

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews() {
        backgroundColor = .accentSoft
        // 付箋は角がわずかに丸いだけ。影を外に落とすため applyCornerRadius は使わず clipsToBounds は立てない
        layer.cornerRadius = 2
        clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.14
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 5)

        foldLayer.fillColor = UIColor.black.withAlphaComponent(0.12).cgColor
        layer.addSublayer(foldLayer)

        label.numberOfLines = 0
        label.textColor = .textPrimary
        label.font = .journal(.subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: .symbol(Symbol.next, textStyle: .footnote, weight: .bold))
        chevron.tintColor = .textPrimary
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

        // 貼ってあるように、わずかに傾ける
        transform = CGAffineTransform(rotationAngle: -1.2 * .pi / 180)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 右下の角がめくれた三角形。bounds が決まってから毎回引き直す
        let size = Self.foldSize
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.maxX - size, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - size))
        path.close()
        foldLayer.path = path.cgPath
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

    /// テストから文言と書体を確かめるための入口
    var textLabelForTesting: UILabel { label }
}
