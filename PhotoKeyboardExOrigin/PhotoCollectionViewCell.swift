//
//  PhotoCollectionViewCell.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Lottie
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
                choiceCoverLabel.textColor = .accent
                choiceCover2View.backgroundColor = .accent
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
        self.backgroundColor = .keyboardSurface
        photoImageView.backgroundColor = .keyboardBase
        titleLabel.textColor = .textPrimary
        choiceCoverView.animation = PhotoCollectionViewCell.fireworksAnimation
    }

    private var linkOverlay: UIView?

    /// 「アプリから画像を追加」セル用。拡張から imperative に URL を開けないため、
    /// セル全体に SwiftUI の Link を重ねてタップを受け取らせる。
    func attachOpenAppLink(url: URL, onTap: @escaping () -> Void) {
        guard linkOverlay == nil else { return }
        let overlay = KeyboardLinkOverlayView(url: url, onTap: onTap)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        linkOverlay = overlay
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 解放しないと古い画像がメモリに残り続け、キーボード拡張のメモリ上限を圧迫する
        photoImageView.image = nil
        titleLabel.text = nil
        // 写真セルに使い回されたときにリンクが残らないようにする
        linkOverlay?.removeFromSuperview()
        linkOverlay = nil
        // 止めないと再生中のアニメーションが、そのセルを使い回す別の写真へ引き継がれ、
        // 隣のセルをタップしたように見えてしまう
        choiceCoverView.stop()
        isCheck = false
    }

    func configure(photo: RealmPhoto) {
        // フル解像度をデコードするとスクロールだけでメモリ上限に達するため縮小版を使う
        let maxPixelSize = max(bounds.width, bounds.height) * UIScreen.main.scale
        photoImageView.image = photo.thumbnail(maxPixelSize: maxPixelSize) ?? photo.image
        photoImageView.contentMode = .scaleAspectFill
        titleLabel.textColor = .textPrimary
        titleLabel.text = photo.text
        choiceCover2View.alpha = 0.3
    }

    func addCellconfigure() {
        photoImageView.image = .symbol(Symbol.add, pointSize: 44)
        photoImageView.tintColor = .accent
        photoImageView.contentMode = .center
        photoImageView.contentMode = .center
        titleLabel.textColor = .accent
        titleLabel.text = LocalizeKey.addPhotoFromApp.localizedString()
        choiceCover2View.isHidden = true
        choiceCoverLabel.isHidden = true
    }
}
