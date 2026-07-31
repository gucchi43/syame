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
    private var aspectRatioConstraint: NSLayoutConstraint?

    /// セルの高さが極端にならないよう縦横比を制限する
    private static let minAspectRatio: CGFloat = 0.6
    private static let maxAspectRatio: CGFloat = 1.6

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
//        self.contentView.layer.borderWidth = 1.0
//        self.contentView.layer.borderColor = UIColor.acGreen().cgColor
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
    static func aspectRatio(imageWidth: Int, imageHeight: Int) -> CGFloat {
        // 寸法が取れない古いデータもあるので、その場合は正方形にする
        guard imageWidth > 0, imageHeight > 0 else { return 1.0 }
        let raw = CGFloat(imageHeight) / CGFloat(imageWidth)
        return min(max(raw, minAspectRatio), maxAspectRatio)
    }

    private func applyAspectRatio(imageWidth: Int, imageHeight: Int) {
        aspectRatioConstraint?.isActive = false

        let ratio = PhotoCollectionViewCell.aspectRatio(imageWidth: imageWidth, imageHeight: imageHeight)
        let constraint = photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor,
                                                                multiplier: ratio)
        // セルの自己サイズ計算中に一時的な制約衝突でログが出ないよう必須より一段下げる
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        aspectRatioConstraint = constraint
    }

    func configure(photo: RealmPhoto, saved: Bool) {
        applyAspectRatio(imageWidth: photo.imageWidth, imageHeight: photo.imageHeight)
        photoImageView.image = photo.image
        countNumLabel.text = String(photo.useNum)
        titleLabel.text = photo.text
        titleLabel.sizeToFit()
        saveButtonState(saved: saved)
    }

    func configure(doc: OFirePhoto? , saved: Bool) {
        imageTask?.cancel()
        imageTask = nil
        self.photoImageView.image = nil
        currentImageURL = nil
        guard let doc = doc else { return }
        // 画像の到着を待たずに高さを確定させる。待つとタブごとに高さが変わる
        applyAspectRatio(imageWidth: doc.imageWidth, imageHeight: doc.imageHeight)
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
