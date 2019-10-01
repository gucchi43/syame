//
//  TextCollectionViewCell.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/09/30.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor

class TextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var coverView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.textColor = .white
        coverView.layer.cornerRadius = 2.0
        coverView.clipsToBounds = true
        coverView.backgroundColor = UIColor.bgDark().lighter(amount: 0.2)
    }
    
    func configure(content: String) {
        textLabel.text = content
    }

}
