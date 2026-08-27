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
    @IBOutlet weak var captionTopConstraint: NSLayoutConstraint!
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
        // 字幕は画像に添えるものなので、見出し級の大きさから一段落とす
        let base = UIFont.scaled(.title2, weight: .bold)
        // strokeWidth は負値で「塗りつぶし＋フチ」になる。正値だと中抜きの文字になる。
        // 和文書体はイタリック体を持たないため、傾きは obliqueness で幾何的にかける
        captionLabel.attributedText = NSAttributedString(string: text, attributes: [
            .font: base.withSize(base.pointSize * 0.7),
            .foregroundColor: UIColor.onAurora,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0,
            .obliqueness: 0.2,
            .paragraphStyle: paragraph
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        positionSubtitleUnderImage()
    }

    /// 字幕を画像の下端のすぐ下に置く。
    ///
    /// 画像は縦横比を保って収まるため、下端の位置は画像ごとに変わる。
    /// 画面いっぱいに伸びる縦長の画像では下端が画面の外に出るので、
    /// 閉じるボタンに掛からないところで止める。
    private func positionSubtitleUnderImage() {
        guard let size = zoomImageView.image?.size, size.width > 0, size.height > 0 else { return }
        let area = scrollView.frame
        let scale = min(area.width / size.width, area.height / size.height)
        let imageBottom = area.minY + (area.height + size.height * scale) / 2
        // 字幕が閉じるボタンに重ならない下限
        let lowest = closeButton.frame.minY - Spacing.s - bgView.frame.height
        let top = min(imageBottom + Spacing.s, lowest) - view.safeAreaInsets.top
        // 制約の変更は再度レイアウトを呼ぶため、動いていないときは何もしない
        guard abs(captionTopConstraint.constant - top) > 0.5 else { return }
        captionTopConstraint.constant = top
        view.layoutIfNeeded()
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
