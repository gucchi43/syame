//
//  GuideChatView.swift
//  PhotoKeyboardEx
//

import UIKit
import PhotoKeyboardFramework

/// 手順③「そのまま送信」の図。
///
/// 舞台は他社アプリのトーク画面だが、実物を写すことはできない。
/// 「会話の中に、貼った画像がそのまま並ぶ」という結末だけを描く。
/// 時刻・既読・相手のアイコンは入れない。特定のアプリの意匠に寄りすぎる。
final class GuideChatView: UIView {

    /// 送った画像の幅。図全体に対する比。会話の中の一要素に見える大きさにする
    private static let sentPhotoWidthRatio: CGFloat = 0.45

    init(sentPhoto: UIImage) {
        super.init(frame: .zero)
        setupSubviews(sentPhoto: sentPhoto)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupSubviews(sentPhoto: UIImage) {
        // 図の面。地(bgBase)のままだと画面に溶けて「図」に見えない
        backgroundColor = .bgSurface
        applyCornerRadius(Radius.card)
        clipsToBounds = true

        // 相手の発言。左に寄せる
        let incoming = UIView()
        incoming.backgroundColor = .bgBase
        incoming.applyCornerRadius(Radius.small)
        incoming.translatesAutoresizingMaskIntoConstraints = false
        addSubview(incoming)

        // 自分が送った画像。右に寄せる
        let sent = UIImageView(image: sentPhoto)
        sent.contentMode = .scaleAspectFill
        sent.clipsToBounds = true
        sent.applyCornerRadius(Radius.small)
        sent.translatesAutoresizingMaskIntoConstraints = false
        // 大きさは縦横比で決める。UIImageView の intrinsicContentSize に任せると
        // 元画像の実寸(見本は800x800)まで膨らんで図が画面からはみ出す
        sent.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        sent.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sent.setContentHuggingPriority(.defaultLow, for: .vertical)
        addSubview(sent)

        NSLayoutConstraint.activate([
            incoming.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            incoming.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            incoming.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.45),
            incoming.heightAnchor.constraint(equalToConstant: 28),

            sent.topAnchor.constraint(equalTo: incoming.bottomAnchor, constant: Spacing.s),
            sent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            sent.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            sent.widthAnchor.constraint(equalTo: widthAnchor,
                                        multiplier: GuideChatView.sentPhotoWidthRatio),
            sent.heightAnchor.constraint(equalTo: sent.widthAnchor)
        ])
    }
}
