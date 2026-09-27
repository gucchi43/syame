//
//  StickerButton.swift
//  PhotoKeyboardEx
//
//  付箋を丸く切ったシールの追加ボタン。少し傾け、内側に点線の円。
//

import UIKit
import PhotoKeyboardFramework

final class StickerButton: UIControl {
    let diameter: CGFloat
    let restingAngle: CGFloat = -6 * .pi / 180
    private let imageView = UIImageView()
    private let ring = CAShapeLayer()

    init(symbol: String, diameter: CGFloat = 64) {
        self.diameter = diameter
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        backgroundColor = .accentSoft
        layer.cornerRadius = diameter / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 8)
        ring.fillColor = UIColor.clear.cgColor
        ring.lineDashPattern = [3, 3]
        ring.lineWidth = 1
        layer.addSublayer(ring)
        imageView.image = .symbol(symbol, pointSize: diameter * 0.42, weight: .regular)
        imageView.tintColor = .textPrimary
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: diameter),
                                     heightAnchor.constraint(equalToConstant: diameter)])
        transform = CGAffineTransform(rotationAngle: restingAngle)
        accessibilityTraits = .button
        accessibilityLabel = LocalizeKey.journalAddPhotoAccessibility.localizedString()
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// テストから点線リングの層を確かめるための入口
    var ringLayerForTesting: CAShapeLayer { ring }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        ring.frame = bounds
        ring.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 4, dy: 4)).cgPath
        ring.strokeColor = UIColor.textPrimary.withAlphaComponent(0.25).resolvedColor(with: traitCollection).cgColor
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        // 点線の色は CGColor なので、明暗が変わったら引き直す
        setNeedsLayout()
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            if isHighlighted {
                Haptic.play(.tap)
                Motion.pressDown(self)
            } else {
                Motion.release(self)
            }
        }
    }
}
