//
//  NextSpotCell.swift
//  PhotoKeyboardEx
//
//  「次はここ」の点線の枠。残り枚数を枠の下に出し、いっぱいなら文言ごと書き換わって
//  押せないただの表示になる。
//

import UIKit
import PhotoKeyboardFramework

final class NextSpotCell: UICollectionViewCell {
    static let reuseIdentifier = "NextSpotCell"
    /// remaining が nil なら残り枚数を出さない(プレミアムは上限が無い)
    enum State: Equatable { case next(remaining: Int?), full }

    let titleLabel = UILabel()
    let remainingLabel = UILabel()
    private let border = CAShapeLayer()
    private(set) var state: State = .next(remaining: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        border.fillColor = UIColor.clear.cgColor
        border.lineDashPattern = [5, 4]
        border.lineWidth = 1.5
        contentView.layer.addSublayer(border)
        [titleLabel, remainingLabel].forEach {
            $0.font = .journal(.subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .pencil
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        remainingLabel.font = .journal(.footnote)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -16),
            remainingLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            remainingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(state: State) {
        self.state = state
        switch state {
        case .next(let remaining):
            titleLabel.text = LocalizeKey.journalNextSpot.localizedString()
            remainingLabel.text = remaining.map { LocalizeKey.journalRemaining.localizedString($0) }
            border.isHidden = false
            accessibilityLabel = LocalizeKey.journalAddPhotoAccessibility.localizedString()
            // 画面に書いてある「あと n 枚」を、VoiceOver でも値として読む
            accessibilityValue = remainingLabel.text
            accessibilityTraits = .button
        case .full:
            titleLabel.text = LocalizeKey.journalFull.localizedString()
            remainingLabel.text = nil
            border.isHidden = true
            accessibilityLabel = titleLabel.text
            // 題名がすでに「このノートはいっぱい」なので、値で同じ文言を重ねて読ませない
            accessibilityValue = nil
            accessibilityTraits = .staticText
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = contentView.bounds
        border.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 3).cgPath
        border.strokeColor = UIColor.pencil.resolvedColor(with: traitCollection).cgColor
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        // 点線の色は CGColor なので、明暗が変わったら引き直す
        setNeedsLayout()
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, case .next = state else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }

    /// 「いっぱい」を鉛筆で書くように左から見せる。視差効果を減らす設定ならフェードだけ
    func revealWriting(completion: @escaping () -> Void) {
        if Motion.isReduced {
            titleLabel.alpha = 0
            UIView.animate(withDuration: 0.3, animations: { self.titleLabel.alpha = 1 }) { _ in completion() }
            return
        }
        // レイアウト前で幅が定まっていないときは、マスクせず即座に完了する
        guard titleLabel.bounds.width > 0 else {
            completion()
            return
        }
        let mask = CALayer()
        mask.backgroundColor = UIColor.black.cgColor
        titleLabel.layer.mask = mask
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.titleLabel.layer.mask = nil
            completion()
        }
        let grow = CABasicAnimation(keyPath: "bounds.size.width")
        grow.fromValue = 0
        grow.toValue = titleLabel.bounds.width
        grow.duration = 0.8
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.position = .zero
        mask.bounds = CGRect(x: 0, y: 0, width: titleLabel.bounds.width, height: titleLabel.bounds.height)
        mask.add(grow, forKey: "write")
        CATransaction.commit()
    }
}
