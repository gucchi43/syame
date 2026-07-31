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
    
    private var imageTask: URLSessionDataTask?
    /// 非同期取得の完了時に、セルが別の写真へ再利用されていないか判定するための現在のURL
    private var currentImageURL: URL?
    override func awakeFromNib() {
        super.awakeFromNib()
        baseLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentImageURL = nil
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
    }

    /// 画像の縦横比からセルの高さを決める。
    /// 画像ビューに高さの制約が無いと、読み込み済みかどうかで高さが変わってしまい、
    /// 同じ写真でもタブによって表示が変わる(キャッシュ済みのタブだけ極端に高くなる)。
    func configure(photo: RealmPhoto, saved: Bool) {
        photoImageView.image = photo.image
        countNumLabel.text = String(photo.useNum)
        titleLabel.text = photo.text
        titleLabel.sizeToFit()
        saveButtonState(saved: saved)
    }

    func configure(serverPhoto: Photo?, saved: Bool) {
        imageTask?.cancel()
        imageTask = nil
        self.photoImageView.image = nil
        currentImageURL = nil
        guard let doc = serverPhoto else { return }
        if let url = URL(string: doc.imageUrl) {
            currentImageURL = url
            imageTask = RemoteImageLoader.shared.load(url: url) { [weak self] image in
                // 取得中にセルが別の写真へ再利用されていたら反映しない
                guard let self = self, self.currentImageURL == url else { return }
                self.photoImageView.image = image
            }
        }
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
