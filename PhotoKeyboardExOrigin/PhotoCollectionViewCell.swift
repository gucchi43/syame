//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Lottie

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var choiceCoverView: AnimationView!
    @IBOutlet weak var choiceCover2View: UIView!
    @IBOutlet weak var choiceCoverLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(model: Model) {
        photoImageView.image = model.photo
        photoImageView.contentMode = .scaleAspectFill
        titleLabel.text = model.title
        let animation = Animation.named("fireworks", subdirectory: "LottieFile")
        choiceCoverView.animation = animation
        choiceCover2View.alpha = 0.3
        if model.isSelected {
            choiceCover2View.isHidden = false
            choiceCoverLabel.isHidden = false
        } else {
            choiceCover2View.isHidden = true
            choiceCoverLabel.isHidden = true
        }
    }
    
    func choice() {
        choiceCoverView.isHidden = false
    }
    
    func unChoice() {
        choiceCoverView.isHidden = true
    }
}
