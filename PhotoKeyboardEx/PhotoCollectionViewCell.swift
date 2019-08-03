//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import FontAwesome_swift

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(model: Model) {
        photoImageView.image = model.photo
        photoImageView.contentMode = .scaleAspectFill
        titleLabel.text = model.title
//        titleLabel.font = UIFont.fontAwesome(ofSize: 20, style: .brands)
//        titleLabel.text = String.fontAwesomeIcon(name: .github)
    }

}
