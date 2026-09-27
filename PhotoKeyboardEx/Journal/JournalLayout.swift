//
//  JournalLayout.swift
//  PhotoKeyboardEx
//
//  ノートの並べ方。貼り方は JournalPlacer が決め、ここはそれを枠と回転に変えるだけ。
//  セクション 0 が写真、セクション 1 が「次はここ」の 1 マス。
//

import UIKit

final class JournalLayout: UICollectionViewLayout {
    static let captionKind = "JournalCaption"
    static let headerKind = "JournalHeader"
    static let headerHeight: CGFloat = 28
    static let bottomClearance: CGFloat = 140
    /// 写真の並びを始める位置。1 枚目には必ず荷札が付き、写真の上端から
    /// PastedPhotoCell.ticketRise ぶん上へ張り出す。見出しの下に荷札とテープのぶんを
    /// 空けておかないと、荷札が見出しの日付に重なる
    static let contentTop: CGFloat = headerHeight + 8 + PastedPhotoCell.ticketRise + 4

    var itemsProvider: () -> [JournalItemInput] = { [] }
    private(set) var placements: [JournalPlacement] = []

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    private var captionAttributes: [UICollectionViewLayoutAttributes] = []
    private var headerAttributes: UICollectionViewLayoutAttributes?
    private var spotAttributes: UICollectionViewLayoutAttributes?
    private var contentHeight: CGFloat = 0
    private var width: CGFloat { collectionView?.bounds.width ?? 0 }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        let items = itemsProvider()
        let count = collectionView.numberOfSections > 0 ? collectionView.numberOfItems(inSection: 0) : 0
        // データソースとの食い違いで落ちないよう、少ない方に合わせる
        let inputs = Array(items.prefix(count))
        placements = JournalPlacer.place(inputs, width: width, top: JournalLayout.contentTop)

        itemAttributes = placements.enumerated().map { index, p in
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attrs.size = p.frame.size
            attrs.center = CGPoint(x: p.frame.midX, y: p.frame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: p.angle)
            attrs.zIndex = index * 2
            return attrs
        }
        captionAttributes = placements.enumerated().map { index, p in
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: JournalLayout.captionKind,
                                                         with: IndexPath(item: index, section: 0))
            attrs.size = p.captionFrame.size
            attrs.center = CGPoint(x: p.captionFrame.midX, y: p.captionFrame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: p.captionAngle)
            attrs.zIndex = index * 2 + 1
            return attrs
        }
        let header = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: JournalLayout.headerKind,
                                                      with: IndexPath(item: 0, section: 0))
        header.frame = CGRect(x: 0, y: 0, width: width, height: JournalLayout.headerHeight)
        headerAttributes = header

        if collectionView.numberOfSections > 1, collectionView.numberOfItems(inSection: 1) > 0 {
            let spot = JournalPlacer.nextSpot(after: placements, width: width, top: JournalLayout.contentTop)
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 1))
            attrs.size = spot.frame.size
            attrs.center = CGPoint(x: spot.frame.midX, y: spot.frame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: spot.angle)
            attrs.zIndex = placements.count * 2 + 1
            spotAttributes = attrs
            // spot.frame は回転前の枠。回転を掛けた attrs.frame (外接矩形) の下端を使わないと
            // 「次はここ」が回転で下にはみ出したぶんだけ追加ボタンの余白に食い込んでしまう
            contentHeight = attrs.frame.maxY + JournalLayout.bottomClearance
        } else {
            spotAttributes = nil
            // placements.last?.bottom ではなく回転を掛けた itemAttributes の外接矩形の下端を使う。
            // 前者は回転前の値で、回転による下へのはみ出し分を見落とすため
            contentHeight = (itemAttributes.last?.frame.maxY ?? JournalLayout.headerHeight) + JournalLayout.bottomClearance
        }
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: width, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var all = itemAttributes + captionAttributes
        if let header = headerAttributes { all.append(header) }
        if let spot = spotAttributes { all.append(spot) }
        return all.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == 1 { return spotAttributes }
        return itemAttributes.indices.contains(indexPath.item) ? itemAttributes[indexPath.item] : nil
    }

    override func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch kind {
        case JournalLayout.headerKind: return headerAttributes
        case JournalLayout.captionKind:
            return captionAttributes.indices.contains(indexPath.item) ? captionAttributes[indexPath.item] : nil
        default: return nil
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.width != collectionView?.bounds.width
    }
}
