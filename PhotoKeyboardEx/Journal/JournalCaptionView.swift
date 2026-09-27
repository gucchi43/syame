//
//  JournalCaptionView.swift
//  PhotoKeyboardEx
//
//  写真に添える題名。手書きの書体で 3 行までにし、それ以上は省略する。
//  写真側 (PastedPhotoCell) が「題名、写真」とまとめて読むので、ここは読み上げない。
//

import UIKit
import PhotoKeyboardFramework

final class JournalCaptionView: UICollectionReusableView {
    static let reuseIdentifier = "JournalCaptionView"

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .journal(.footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }

    func configure(text: String) {
        label.text = text
    }
}
