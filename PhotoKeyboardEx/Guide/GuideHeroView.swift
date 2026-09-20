//
//  GuideHeroView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 起動直後に出す、何をするアプリかを一目で伝える図。
///
/// 「キーボードの画像をタップすると、トークにそのまま貼られる」という流れを
/// 上下に並べて示す。App Store の1枚目と同じ構成だが、画像として焼かずに組む。
/// 焼くと文言が日本語のまま英語ロケールに出て、ダークモードにも追従しない。
/// サムネイルには利用者自身の保存画像が入るので、現物ともズレない。
final class GuideHeroView: UIView {

    /// バッジを重ねるのはキーボード側。タップの起点がそこだと分かる
    private let badge = UILabel()

    private weak var chat: GuideChatView?
    private weak var strip: GuideKeyboardStripView?
    private weak var pill: UIView?
    private var isAnimating = false

    init(photos: [UIImage], sentPhoto: UIImage) {
        super.init(frame: .zero)
        setupSubviews(photos: photos, sentPhoto: sentPhoto)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews(photos: [UIImage], sentPhoto: UIImage) {
        let chat = GuideChatView(sentPhoto: sentPhoto)
        chat.translatesAutoresizingMaskIntoConstraints = false
        self.chat = chat

        let strip = GuideKeyboardStripView(photos: photos,
                                           titles: GuideSampleGallery.titles,
                                           showsChrome: true)
        strip.translatesAutoresizingMaskIntoConstraints = false
        self.strip = strip

        // 上(トーク)から下(キーボード)へ、貼られた先と貼る元の関係を示す
        let column = UIStackView(arrangedSubviews: [chat, makeBadgeRow(), strip])
        column.axis = .vertical
        column.alignment = .fill
        column.spacing = Spacing.s
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// 「タップして、貼るだけ。」の一行。上下の図の関係を言葉で繋ぐ
    private func makeBadgeRow() -> UIView {
        badge.text = LocalizeKey.heroTapAndPaste.localizedString()
        badge.font = .scaled(.caption1, weight: .bold)
        badge.adjustsFontForContentSizeCategory = true
        badge.textColor = .onAccent
        badge.textAlignment = .center
        badge.numberOfLines = 0
        badge.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.backgroundColor = .accent
        pill.applyCornerRadius(Radius.small)
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(badge)

        let row = UIView()
        row.addSubview(pill)
        pill.translatesAutoresizingMaskIntoConstraints = false
        self.pill = pill

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: pill.topAnchor, constant: Spacing.s),
            badge.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -Spacing.s),
            badge.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: Spacing.m),
            badge.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -Spacing.m),
            pill.topAnchor.constraint(equalTo: row.topAnchor),
            pill.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            pill.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            pill.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor)
        ])
        return row
    }
}

// MARK: - 動き

extension GuideHeroView {

    /// 「タップ → コピー → トークに届く」を繰り返す。
    ///
    /// 静止画だと3つの絵が並んでいるだけで、どれが原因でどれが結果かが読めない。
    /// 実際の操作と同じ順に動かすことで、説明を読まなくても関係が分かる。
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        resetForCycle()
        runCycle()
    }

    func stopAnimating() {
        isAnimating = false
        layer.removeAllAnimations()
        // 動かない環境(省電力・アクセシビリティ設定)で欠けたまま残らないよう完成形に戻す
        chat?.sentPhotoView?.alpha = 1
        chat?.sentPhotoView?.transform = .identity
        strip?.copyBadge?.alpha = 1
        strip?.copyBadge?.transform = .identity
        pill?.alpha = 1
        pill?.transform = .identity
    }

    private func runCycle() {
        guard isAnimating, window != nil else {
            // 画面に出ていないあいだは回さない。無駄に電池を使う
            isAnimating = false
            return
        }
        resetForCycle()

        // ① タップされたセルが沈む
        UIView.animate(withDuration: 0.18, delay: 0.4, options: [.curveEaseOut]) {
            self.strip?.tappedCell?.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        } completion: { _ in
            UIView.animate(withDuration: 0.18) {
                self.strip?.tappedCell?.transform = .identity
            }
            // ② コピーの印が出る
            UIView.animate(withDuration: 0.25, delay: 0.1, options: [.curveEaseOut]) {
                self.strip?.copyBadge?.alpha = 1
                self.strip?.copyBadge?.transform = .identity
            } completion: { _ in
                // ③ 「タップして、貼るだけ。」が浮かぶ
                UIView.animate(withDuration: 0.25, delay: 0.15, options: [.curveEaseOut]) {
                    self.pill?.alpha = 1
                    self.pill?.transform = .identity
                } completion: { _ in
                    // ④ トークに画像が届く
                    UIView.animate(withDuration: 0.35, delay: 0.2,
                                   usingSpringWithDamping: 0.75, initialSpringVelocity: 0.6,
                                   options: [.curveEaseOut]) {
                        self.chat?.sentPhotoView?.alpha = 1
                        self.chat?.sentPhotoView?.transform = .identity
                    } completion: { _ in
                        // しばらく見せてから繰り返す
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                            self?.runCycle()
                        }
                    }
                }
            }
        }
    }

    /// 1周ぶんの初期状態に戻す
    private func resetForCycle() {
        chat?.sentPhotoView?.alpha = 0
        chat?.sentPhotoView?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        strip?.copyBadge?.alpha = 0
        strip?.copyBadge?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        pill?.alpha = 0
        pill?.transform = CGAffineTransform(translationX: 0, y: 6)
        strip?.tappedCell?.transform = .identity
    }
}
