//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import DynamicColor

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
        self.contentView.layer.cornerRadius = 8
        self.contentView.clipsToBounds = true
        let bgkDarkLight = UIColor.bgDark().lighter(amount: 0.1)
        self.contentView.backgroundColor = bgkDarkLight
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = UIColor.bgDark().lighter(amount: 0.2)
        // 画像そのものの寸法でセルの高さが決まらないようにする。
        // これを下げないと 1080px の画像で 1080pt のセルになってしまう。
        photoImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        photoImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        photoImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        photoImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        countIconLabel.font = UIFont.fontAwesome(ofSize: 16, style: .solid)
        countIconLabel.text = String.fontAwesomeIcon(name: .download)
        saveButton.layer.borderWidth = 1
        saveButton.layer.cornerRadius = 4
        saveButton.clipsToBounds = true
        // 公開フィードが無くなり、このボタンは「マイボードから取り除く」意味になった
        saveButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 14, style: .solid)
        saveButton.setTitle(String.fontAwesomeIcon(name: .times), for: .normal)
        saveButton.setTitleColor(.acGreen(), for: .normal)
        saveButton.backgroundColor = .clear
        saveButton.layer.borderColor = UIColor.acGreen().cgColor
    }

    func configure(photo: RealmPhoto, saved: Bool) {
        photoImageView.image = photo.image
        countNumLabel.text = String(photo.useNum)
        titleLabel.text = photo.text
        titleLabel.sizeToFit()
    }
}
