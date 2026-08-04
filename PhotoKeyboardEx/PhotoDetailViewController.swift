//
//  PhotoDetailViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework

/// 保存済み画像の拡大表示。
/// 公開投稿を廃止し、表示するのは自分が保存した画像だけになったため、通報とブロックは撤去した。
class PhotoDetailViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    private var zoomImageView: UIImageView!
    var rPhoto: RealmPhoto?

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        zoomImageView = UIImageView()
        zoomImageView.contentMode = .scaleAspectFit
        zoomImageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(zoomImageView)
        NSLayoutConstraint.activate([
            zoomImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            zoomImageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            zoomImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            zoomImageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            zoomImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            zoomImageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        zoomImageView.image = rPhoto?.image

        closeButton.tintColor = .accent
        closeButton.applySymbol(Symbol.close)
        closeButton.titleLabel?.shadowColor = .black
        closeButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)

        // 通報・ブロックが無くなり中身が空になったため隠す。
        // アプリ内コピー導線を実装する際にこのボタンを再利用する。
        otherButton.isHidden = true

        self.view.backgroundColor = .bgBase
        bgView.backgroundColor = UIColor.clear
        captionLabel.textColor = .textPrimary
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.sizeToFit()
        captionLabel.shadowColor = .black
        captionLabel.shadowOffset = CGSize(width: 1, height: 1)
        captionLabel.text = rPhoto?.text
    }

    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    /// Storyboardからの接続が残っているため定義だけ残す。ボタン自体は隠してある。
    @IBAction func tapOtherButton(_ sender: Any) {
    }
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }
}
