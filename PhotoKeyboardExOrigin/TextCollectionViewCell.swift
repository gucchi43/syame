//
//  TextCollectionViewCell.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/09/30.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

class TextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var coverView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.textColor = .textPrimary
        coverView.applyCornerRadius(Radius.small)
        coverView.clipsToBounds = true
        coverView.backgroundColor = .keyboardSurface
    }
    
    func configure(content: String) {
        textLabel.text = content
    }

}
