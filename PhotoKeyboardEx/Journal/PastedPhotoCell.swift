//
//  PastedPhotoCell.swift
//  PhotoKeyboardEx
//
//  ノートに貼った写真 1 枚。形・テープ・小物は JournalPlacement に従う。
//  回転はレイアウトが持つので、ここでは回さない。
//

import UIKit
import PhotoKeyboardFramework

final class PastedPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "PastedPhotoCell"
    static let polaroidSide: CGFloat = 7
    static let polaroidBottom: CGFloat = 26
    /// 荷札が写真の上端からどれだけ上へ張り出すか
    static let ticketRise: CGFloat = 26

    private let paperView = UIView()          // ポラロイドの縁。紙焼きのときは写真と同じ大きさ
    private let photoView = UIImageView()
    private var tapeViews: [UIView] = []
    private var propView: UIView?
    private var shape: PrintShape = .print
    private var tape: TapeStyle = .black
    private var prop: JournalProp = .none

    var photoViewForTesting: UIImageView { photoView }
    var tapeViewsForTesting: [UIView] { tapeViews }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        paperView.backgroundColor = .bgSurface
        paperView.layer.shadowColor = UIColor.black.cgColor
        paperView.layer.shadowOpacity = 0.22
        paperView.layer.shadowRadius = 5
        paperView.layer.shadowOffset = CGSize(width: 0, height: 3)
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        contentView.addSubview(paperView)
        paperView.addSubview(photoView)
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
        tapeViews.forEach { $0.removeFromSuperview() }
        tapeViews = []
        propView?.removeFromSuperview()
        propView = nil
    }

    func configure(image: UIImage?, placement: JournalPlacement, ticketText: String?, title: String) {
        photoView.image = image
        shape = placement.shape
        tape = placement.tape
        prop = placement.prop
        accessibilityLabel = LocalizeKey.journalPhotoAccessibility.localizedString(title)

        tapeViews.forEach { $0.removeFromSuperview() }
        switch placement.tape {
        case .corners: tapeViews = [TapeView(style: .black), TapeView(style: .black)]
        case .clip: tapeViews = [ClipView()]
        default: tapeViews = [TapeView(style: placement.tape)]
        }
        tapeViews.forEach { contentView.addSubview($0) }

        propView?.removeFromSuperview()
        switch placement.prop {
        case .ticket:
            let ticket = TicketView()
            ticket.text = ticketText
            propView = ticket
        case .star: propView = StarStickerView()
        case .none: propView = nil
        }
        if let propView = propView { contentView.addSubview(propView) }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.frame = contentView.bounds
        switch shape {
        case .polaroid:
            photoView.frame = CGRect(x: Self.polaroidSide, y: Self.polaroidSide,
                                     width: bounds.width - Self.polaroidSide * 2,
                                     height: bounds.height - Self.polaroidSide - Self.polaroidBottom)
            paperView.layer.mask = nil
        case .torn:
            photoView.frame = paperView.bounds
            paperView.layer.mask = TornEdge.mask(for: paperView.bounds)
        case .print, .landscape:
            photoView.frame = paperView.bounds
            paperView.layer.mask = nil
        }
        paperView.layer.shadowPath = UIBezierPath(rect: paperView.bounds).cgPath

        switch tape {
        case .corners where tapeViews.count == 2:
            tapeViews[0].bounds = CGRect(x: 0, y: 0, width: 44, height: 16)
            tapeViews[0].center = CGPoint(x: bounds.maxX - 4, y: 10)
            tapeViews[0].transform = CGAffineTransform(rotationAngle: .pi / 4)
            tapeViews[1].bounds = tapeViews[0].bounds
            tapeViews[1].center = CGPoint(x: 4, y: bounds.maxY - 10)
            tapeViews[1].transform = CGAffineTransform(rotationAngle: .pi / 4)
        case .clip:
            tapeViews.first?.frame = CGRect(x: bounds.midX - 6, y: -16, width: 12, height: 34)
        default:
            let width: CGFloat = tape == .long ? 92 : 58
            tapeViews.first?.bounds = CGRect(x: 0, y: 0, width: width, height: 17)
            tapeViews.first?.center = CGPoint(x: bounds.midX, y: 0)
            tapeViews.first?.transform = CGAffineTransform(rotationAngle: -0.06)
        }

        switch prop {
        case .ticket: propView?.frame = CGRect(x: -10, y: -Self.ticketRise, width: 88, height: 20)
        case .star: propView?.frame = CGRect(x: bounds.maxX - 14, y: bounds.maxY - 14, width: 22, height: 22)
        case .none: break
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
}
