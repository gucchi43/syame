//
//  JournalProps.swift
//  PhotoKeyboardEx
//
//  ノートの紙と、写真を留める文房具。実在するものだけを描く。
//  画像は持たず、すべて描画で作る(ダークでも色トークンで追従する)。
//

import UIKit
import PhotoKeyboardFramework

/// 方眼ノートの紙
final class PaperBackgroundView: UIView {
    static let gridSpacing: CGFloat = 14
    /// 方眼の模様色。タイルの描き直しを避けるため 1 回だけ作って使い回す
    static let gridPattern: UIColor = gridPatternColor()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        contentMode = .redraw
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.bgBase.setFill()
        context.fill(rect)
        UIColor.paperGrid.setStroke()
        context.setLineWidth(1 / max(window?.screen.scale ?? 2, 1))
        let spacing = PaperBackgroundView.gridSpacing
        var x = (rect.minX / spacing).rounded(.down) * spacing
        while x <= rect.maxX {
            context.move(to: CGPoint(x: x, y: rect.minY)); context.addLine(to: CGPoint(x: x, y: rect.maxY)); x += spacing
        }
        var y = (rect.minY / spacing).rounded(.down) * spacing
        while y <= rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y)); context.addLine(to: CGPoint(x: rect.maxX, y: y)); y += spacing
        }
        context.strokePath()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        setNeedsDisplay()
    }

    /// 方眼1マス分のタイルを animatable な UIColor(patternImage:) として返す。
    /// 一覧の背景色に使うと、スクロールしても中身(写真)と一緒に模様が動く(スクロールビュー自体を動かすため)。
    /// ライト・ダークで別のタイルになるよう、traits ごとに描き直す
    static func gridPatternColor() -> UIColor {
        UIColor { traits in
            let scale = traits.displayScale > 0 ? traits.displayScale : 2
            let size = CGSize(width: gridSpacing, height: gridSpacing)
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.opaque = true
            let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
                let cgContext = context.cgContext
                UIColor.bgBase.resolvedColor(with: traits).setFill()
                cgContext.fill(CGRect(origin: .zero, size: size))
                UIColor.paperGrid.resolvedColor(with: traits).setStroke()
                cgContext.setLineWidth(1 / scale)
                cgContext.move(to: CGPoint(x: 0, y: 0))
                cgContext.addLine(to: CGPoint(x: size.width, y: 0))
                cgContext.move(to: CGPoint(x: 0, y: 0))
                cgContext.addLine(to: CGPoint(x: 0, y: size.height))
                cgContext.strokePath()
            }
            return UIColor(patternImage: image)
        }
    }
}

/// マスキングテープ。黒・白・透明・長い
final class TapeView: UIView {
    let style: TapeStyle

    init(style: TapeStyle) {
        self.style = style
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        applyColor()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyColor() {
        switch style {
        case .black, .long: backgroundColor = UIColor.accent.withAlphaComponent(0.9)
        case .white: backgroundColor = .tapeWhite
        case .clear:
            backgroundColor = .tapeClear
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.textPrimary.withAlphaComponent(0.12).resolvedColor(with: traitCollection).cgColor
        case .corners, .clip: backgroundColor = UIColor.accent.withAlphaComponent(0.9)
        }
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        applyColor()
    }
}

/// ゼムクリップ
final class ClipView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let outer = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: rect.width / 2)
        let inner = UIBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.14),
                                 cornerRadius: rect.width / 3)
        UIColor.pencil.setStroke()
        outer.lineWidth = 1.6
        inner.lineWidth = 1.6
        outer.stroke()
        inner.stroke()
    }
}

/// 荷札。左端が尖り、穴が開いている
final class TicketView: UIView {
    private let label = UILabel()
    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }
    var textLabelForTesting: UILabel { label }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .kraft
        isUserInteractionEnabled = false
        label.font = .label(.caption2)
        label.textColor = .onKraft
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    convenience init() { self.init(frame: .zero) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 6, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 6, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.midY))
        path.close()
        path.append(UIBezierPath(ovalIn: CGRect(x: 6, y: bounds.midY - 2, width: 4, height: 4)).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

/// 星のシール
final class StarStickerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .kraft
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let points: [CGPoint] = [(0.5, 0), (0.61, 0.35), (0.98, 0.35), (0.68, 0.57), (0.79, 0.91),
                                 (0.5, 0.7), (0.21, 0.91), (0.32, 0.57), (0.02, 0.35), (0.39, 0.35)]
            .map { CGPoint(x: $0.0 * bounds.width, y: $0.1 * bounds.height) }
        let path = UIBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.close()
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

/// ちぎった切れ端の形
enum TornEdge {
    static func mask(for bounds: CGRect) -> CAShapeLayer {
        let steps: [CGFloat] = [0.03, 0, 0.02, 0, 0.03, 0, 0.02, 0, 0.03]
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height * steps[0]))
        for (i, ratio) in steps.enumerated() {
            let x = bounds.width * CGFloat(i) / CGFloat(steps.count - 1)
            path.addLine(to: CGPoint(x: x, y: bounds.height * ratio))
        }
        path.addLine(to: CGPoint(x: bounds.maxX * 0.98, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.maxY * 0.98))
        path.close()
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        return layer
    }
}
