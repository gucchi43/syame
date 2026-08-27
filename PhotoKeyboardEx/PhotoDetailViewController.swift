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
        applySubtitle(rPhoto?.text)
    }

    /// 画像の上に重ねる字幕。映画の字幕にならい、白文字を黒フチで縁取る。
    ///
    /// 背後に来るのはアプリの地ではなく画像なので、色は常に白で固定する。
    /// 地に追従する textPrimary ではライトモードで黒文字になり、暗い画像に沈む。
    private func applySubtitle(_ text: String?) {
        guard let text = text, !text.isEmpty else {
            captionLabel.isHidden = true
            return
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        captionLabel.adjustsFontForContentSizeCategory = true
        // strokeWidth は負値で「塗りつぶし＋フチ」になる。正値だと中抜きの文字になる。
        // 和文書体はイタリック体を持たないため、傾きは obliqueness で幾何的にかける
        captionLabel.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.scaled(.title2, weight: .bold),
            .foregroundColor: UIColor.onAurora,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0,
            .obliqueness: 0.2,
            .paragraphStyle: paragraph
        ])
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
