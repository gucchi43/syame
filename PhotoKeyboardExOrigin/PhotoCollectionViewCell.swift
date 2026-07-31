//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Lottie
import DynamicColor
import PhotoKeyboardFramework

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var choiceCoverView: LottieAnimationView!
    @IBOutlet weak var choiceCover2View: UIView!
    @IBOutlet weak var choiceCoverLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isCheck: Bool = false {
        didSet {
            if isCheck {
                let choiceColor = ColorManager.shared.acRandom()
                choiceCoverLabel.textColor = choiceColor
                choiceCover2View.backgroundColor = choiceColor
                choiceCover2View.isHidden = false
                choiceCoverLabel.isHidden = false
            } else {
                choiceCover2View.isHidden = true
                choiceCoverLabel.isHidden = true
            }
        }
    }
    
    /// セル再利用のたびにJSONをパースし直さないよう一度だけ読み込む
    private static let fireworksAnimation = LottieAnimation.named("fireworks", subdirectory: "LottieFile")

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.bgDark().lighter(amount: 0.1)
        photoImageView.backgroundColor = UIColor.bgDark().lighter(amount: 0.2)
        titleLabel.textColor = .white
        choiceCoverView.animation = PhotoCollectionViewCell.fireworksAnimation
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 解放しないと古い画像がメモリに残り続け、キーボード拡張のメモリ上限を圧迫する
        photoImageView.image = nil
        titleLabel.text = nil
    }

    func configure(photo: RealmPhoto) {
        // フル解像度をデコードするとスクロールだけでメモリ上限に達するため縮小版を使う
        let maxPixelSize = max(bounds.width, bounds.height) * UIScreen.main.scale
        photoImageView.image = photo.thumbnail(maxPixelSize: maxPixelSize) ?? photo.image
        photoImageView.contentMode = .scaleAspectFill
        titleLabel.textColor = .white
        titleLabel.text = photo.text
        choiceCover2View.alpha = 0.3
    }

    func addCellconfigure() {
        photoImageView.image = UIImage.fontAwesomeIcon(name: .plus, style: .solid, textColor: .acGreen(), size: CGSize(width: 88, height: 88))
        photoImageView.contentMode = .center
        titleLabel.textColor = .acGreen()
        titleLabel.text = LocalizeKey.addPhotoFromApp.localizedString()
        choiceCover2View.isHidden = true
        choiceCoverLabel.isHidden = true
    }
}
