//
//  JournalHeaderView.swift
//  PhotoKeyboardEx
//
//  ノートの頭に出す見出し。日付とページ番号をタイプライターの書体で書く。
//

import UIKit
import PhotoKeyboardFramework

final class JournalHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "JournalHeaderView"
    private static let leadingInset: CGFloat = 24

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .label(.caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .pencil
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(dateText: String) {
        label.text = "\(dateText) — p.1"
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = label.sizeThatFits(CGSize(width: bounds.width - Self.leadingInset, height: bounds.height))
        label.frame = CGRect(x: Self.leadingInset, y: (bounds.height - size.height) / 2,
                             width: bounds.width - Self.leadingInset, height: size.height)
    }
}
