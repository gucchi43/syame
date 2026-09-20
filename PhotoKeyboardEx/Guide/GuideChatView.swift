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

    /// 送った画像。届く動きを付けるために持つ
    private(set) weak var sentPhotoView: UIView?

    init(sentPhoto: UIImage) {
        super.init(frame: .zero)
        setupSubviews(sentPhoto: sentPhoto)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 相手の吹き出し1つ
    private func makeIncomingBubble(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .scaled(.caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false

        let bubble = UIView()
        bubble.backgroundColor = .bgBase
        bubble.applyCornerRadius(Radius.small)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: Spacing.s),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -Spacing.s),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: Spacing.m),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -Spacing.m)
        ])
        return bubble
    }

    private func setupSubviews(sentPhoto: UIImage) {
        // 図の面。地(bgBase)のままだと画面に溶けて「図」に見えない
        backgroundColor = .bgSurface
        applyCornerRadius(Radius.card)
        clipsToBounds = true

        // 相手の発言。左に寄せる。2つ並べると会話の途中だと分かる
        let incoming = UIStackView(arrangedSubviews: [
            makeIncomingBubble(LocalizeKey.chatIncomingFirst.localizedString()),
            makeIncomingBubble(LocalizeKey.chatIncomingSecond.localizedString())
        ])
        incoming.axis = .vertical
        incoming.alignment = .leading
        incoming.spacing = Spacing.grid * 2
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
        sentPhotoView = sent

        NSLayoutConstraint.activate([
            incoming.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            incoming.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            incoming.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Spacing.m),

            sent.topAnchor.constraint(equalTo: incoming.bottomAnchor, constant: Spacing.s),
            sent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            sent.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m),
            sent.widthAnchor.constraint(equalTo: widthAnchor,
                                        multiplier: GuideChatView.sentPhotoWidthRatio),
            sent.heightAnchor.constraint(equalTo: sent.widthAnchor)
        ])
    }
}
