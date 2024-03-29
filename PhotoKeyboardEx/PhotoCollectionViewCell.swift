//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import FontAwesome_swift
import PhotoKeyboardFramework
import DynamicColor
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI

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
    
    func baseLayout() {
        self.contentView.layer.cornerRadius = 8
        self.contentView.clipsToBounds = true
//        self.contentView.layer.borderWidth = 1.0
//        self.contentView.layer.borderColor = UIColor.acGreen().cgColor
        let bgkDarkLight = UIColor.bgDark().lighter(amount: 0.1)
        self.contentView.backgroundColor = bgkDarkLight
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.backgroundColor = UIColor.bgDark().lighter(amount: 0.2)
        countIconLabel.font = UIFont.fontAwesome(ofSize: 16, style: .solid)
        countIconLabel.text = String.fontAwesomeIcon(name: .download)
        saveButton.layer.borderWidth = 1
        saveButton.layer.cornerRadius = 4
        saveButton.clipsToBounds = true
    }

    func configure(photo: RealmPhoto, saved: Bool) {
        photoImageView.image = photo.image
        countNumLabel.text = String(photo.useNum)
        titleLabel.text = photo.text
        titleLabel.sizeToFit()
        saveButtonState(saved: saved)
    }
    
    func configure(doc: OFirePhoto? , saved: Bool) {
        self.photoImageView.image = nil
        guard let doc = doc else { return }
        let storageref = Storage.storage().reference(forURL: doc.imageUrl)
        photoImageView.sd_setImage(with: storageref)
        titleLabel.text = doc.title
        titleLabel.sizeToFit()
        countNumLabel.text = String(doc.totalSaveCount)
        saveButtonState(saved: saved)
    }
    
    func saveButtonState(saved: Bool) {
        if saved {
            saveButton.setTitle("saved", for: .normal)
            saveButton.setTitleColor(.white, for: .normal)
            saveButton.backgroundColor = .acGreen()
            saveButton.layer.borderColor = UIColor.acGreen().cgColor
        } else {
            saveButton.setTitle("save", for: .normal)
            saveButton.setTitleColor(.acGreen(), for: .normal)
            saveButton.backgroundColor = .clear
            saveButton.layer.borderColor = UIColor.acGreen().cgColor
        }
    }
}
