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
import FontAwesome_swift

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var choiceCoverView: AnimationView!
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.bgDark().lighter(amount: 0.1)
        photoImageView.backgroundColor = UIColor.bgDark().lighter(amount: 0.2)
        titleLabel.textColor = .white
    }
    
    func configure(photo: RealmPhoto) {
        photoImageView.image = photo.image
        photoImageView.contentMode = .scaleAspectFill
        titleLabel.textColor = .white
        titleLabel.text = photo.text
        let animation = Animation.named("fireworks", subdirectory: "LottieFile")
        choiceCoverView.animation = animation
        choiceCover2View.alpha = 0.3
    }
    
    func addCellconfigure() {
        photoImageView.image = UIImage.fontAwesomeIcon(name: .plus, style: .solid, textColor: .acGreen(), size: CGSize(width: 88, height: 88))
        photoImageView.contentMode = .center
        titleLabel.textColor = .acGreen()
        titleLabel.text = "アプリから画像を追加"
    }
}
