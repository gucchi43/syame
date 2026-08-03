//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var countIconLabel: UILabel!
    @IBOutlet weak var countNumLabel: UILabel!

    @IBOutlet weak var baseView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        baseLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        titleLabel.text = nil
    }

    func baseLayout() {
        self.contentView.applyCornerRadius(Radius.card)
        self.contentView.backgroundColor = .bgSurface
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = .bgBase
        // 画像そのものの寸法でセルの高さが決まらないようにする。
        // これを下げないと 1080px の画像で 1080pt のセルになってしまう。
        photoImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        photoImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        photoImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        photoImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        countIconLabel.attributedText = NSAttributedString(
            attachment: NSTextAttachment(image: .symbol(Symbol.saveCount, textStyle: .caption1) ?? UIImage())
        )
        countIconLabel.tintColor = .textSecondary
        saveButton.layer.borderWidth = 1
        saveButton.applyCornerRadius(Radius.small)
        // 公開フィードが無くなり、このボタンは「マイボードから取り除く」意味になった
        saveButton.applySymbol(Symbol.close, textStyle: .caption1)
        saveButton.backgroundColor = .clear
        saveButton.layer.borderColor = UIColor.brandAccent.cgColor
    }

    func configure(photo: RealmPhoto, saved: Bool) {
        photoImageView.image = photo.image
        countNumLabel.text = String(photo.useNum)
        titleLabel.text = photo.text
        titleLabel.sizeToFit()
    }
}
