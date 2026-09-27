//
//  JournalPlacer.swift
//  PhotoKeyboardEx
//
//  写真の id から、ノートへの貼り方(形・大きさ・角度・テープ・位置)を決める。
//  乱数を使わないので、同じ写真はいつ開いても同じ場所に同じ貼り方で出る。
//  Realm も UIKit も知らない。
//

import CoreGraphics

enum PrintShape: Equatable { case print, polaroid, torn, landscape }
enum TapeStyle: Equatable { case black, white, clear, long, corners, clip }
enum JournalProp: Equatable { case none, ticket, star }
enum CaptionSide: Equatable { case beside, below }

struct JournalItemInput: Equatable {
    let id: String
    let aspectRatio: CGFloat
    let dayKey: String
}

struct JournalPlacement: Equatable {
    let frame: CGRect
    let angle: CGFloat
    let shape: PrintShape
    let tape: TapeStyle
    let prop: JournalProp
    let captionFrame: CGRect
    let captionAngle: CGFloat
    let captionSide: CaptionSide
    let bottom: CGFloat
    let isLeft: Bool
}

enum JournalPlacer {
    static let margin: CGFloat = 16
    static let captionMinWidth: CGFloat = 110
    static let captionMaxWidth: CGFloat = 150
    /// 題名の高さ。文字サイズが標準のときの値で、place の captionScale で拡大する
    static let captionHeightBeside: CGFloat = 64
    static let captionHeightBelow: CGFloat = 44
    static let maxAngleDegrees: CGFloat = 9
    static let maxOverlap: CGFloat = 0.2
    static let gap: CGFloat = 10
    static let sizeTiers: [CGFloat] = [0.62, 0.50, 0.40]
    static let tapes: [TapeStyle] = [.black, .white, .clear, .long, .corners, .clip]
    /// 端にぴったり付けると、回転の往復計算で浮動小数点誤差が出て境界を僅かに割ることがあるための内側マージン
    static let boundsEpsilon: CGFloat = 0.01

    /// FNV-1a 64 ビット。Swift の hashValue は起動ごとに変わるので使わない
    static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// captionScale は題名の文字サイズの倍率(Dynamic Type)。UIKit を知らないよう、呼び出し側で求めて渡す
    static func place(_ items: [JournalItemInput], width: CGFloat, top: CGFloat,
                      captionScale: CGFloat = 1) -> [JournalPlacement] {
        var result: [JournalPlacement] = []
        var previous: JournalPlacement?
        var previousDay: String?
        for (index, item) in items.enumerated() {
            let h = fnv1a64(item.id)
            let shape = shape(for: h)
            let photoWidth = (width * sizeTiers[Int((h >> 8) % 3)]).rounded()
            let height = photoHeight(width: photoWidth, shape: shape, aspectRatio: item.aspectRatio)
            let angle = (-maxAngleDegrees + CGFloat((h >> 16) % 37) * 0.5) * .pi / 180
            let tape = tapes[Int((h >> 24) % UInt64(tapes.count))]
            let jitter = CGFloat(Int((h >> 32) % 25) - 12)
            let overlap = CGFloat((h >> 40) % 21) / 100
            let isLeft = index % 2 == 0

            // 回転しても幅に収まるよう、回転後の外形の半幅で左右を詰める
            let halfSpan = (photoWidth * abs(cos(angle)) + height * abs(sin(angle))) / 2
            // この写真自身が回転で上に張り出すぶん。次の写真の食い込み計算はこれを足して初めて
            // 「回転後の見た目」で前の写真の高さの overlap 以内に収まる
            let ownSlack = halfSpanVerticalSlack(angle, photoWidth, height)
            let preferredMidX = isLeft ? margin + photoWidth / 2 + jitter : width - margin - photoWidth / 2 + jitter
            let midX = min(max(preferredMidX, halfSpan + boundsEpsilon), width - halfSpan - boundsEpsilon)

            let y: CGFloat
            if let previous = previous {
                var candidateY = previous.bottom - previous.frame.height * overlap + (overlap == 0 ? gap : 0) + ownSlack
                if previous.captionSide == .beside {
                    // 題名が脇にあるときは、次の写真が題名を隠さないよう題名の下端より下に置く
                    candidateY = max(candidateY, previous.captionFrame.maxY + ownSlack + 4)
                }
                y = candidateY
            } else {
                y = top
            }
            let frame = CGRect(x: midX - photoWidth / 2, y: y, width: photoWidth, height: height)

            // 題名は空いている側へ。狭ければ写真の下
            let freeWidth = isLeft ? width - (midX + halfSpan) - margin : (midX - halfSpan) - margin
            let captionSide: CaptionSide = freeWidth >= captionMinWidth ? .beside : .below
            let captionFrame: CGRect
            if captionSide == .beside {
                let w = min(freeWidth, captionMaxWidth)
                let x = isLeft ? midX + halfSpan + 8 : midX - halfSpan - 8 - w
                captionFrame = CGRect(x: x, y: frame.minY + height * 0.3, width: w, height: (captionHeightBeside * captionScale).rounded(.up))
            } else {
                let w = min(width - margin * 2, photoWidth + 40)
                let x = min(max(midX - w / 2, margin), width - margin - w)
                captionFrame = CGRect(x: x, y: frame.maxY + 8, width: w, height: (captionHeightBelow * captionScale).rounded(.up))
            }
            let captionAngle = -angle / 3

            let prop: JournalProp
            if item.dayKey != previousDay {
                prop = .ticket
            } else {
                prop = (h >> 48) % 5 == 0 ? .star : .none
            }

            let placement = JournalPlacement(frame: frame, angle: angle, shape: shape, tape: tape, prop: prop,
                                             captionFrame: captionFrame, captionAngle: captionAngle,
                                             captionSide: captionSide,
                                             bottom: max(frame.maxY + ownSlack, captionFrame.maxY),
                                             isLeft: isLeft)
            result.append(placement)
            previous = placement
            previousDay = item.dayKey
        }
        return result
    }

    static func nextSpot(after placements: [JournalPlacement], width: CGFloat, top: CGFloat) -> (frame: CGRect, angle: CGFloat) {
        let w = (width * 0.45).rounded()
        let h = (w * 0.8).rounded()
        let isLeft = !(placements.last?.isLeft ?? false)
        let x = isLeft ? margin + 12 : width - margin - 12 - w
        let y = (placements.last?.bottom ?? top) + 20
        let angle: CGFloat = (isLeft ? -7 : 6) * .pi / 180
        return (CGRect(x: x, y: y, width: w, height: h), angle)
    }

    private static func shape(for hash: UInt64) -> PrintShape {
        switch hash % 100 {
        case 0..<40: return .print
        case 40..<65: return .polaroid
        case 65..<85: return .torn
        default: return .landscape
        }
    }

    private static func photoHeight(width: CGFloat, shape: PrintShape, aspectRatio: CGFloat) -> CGFloat {
        switch shape {
        case .landscape: return (width / 1.5).rounded()
        case .polaroid: return (width * 1.18).rounded()
        case .print, .torn:
            let ratio = min(max(aspectRatio > 0 ? aspectRatio : 1, 0.75), 1.33)
            return (width / ratio).rounded()
        }
    }

    /// 回転で下にはみ出すぶん。次の写真がここに潜り込まないよう下端に足す
    private static func halfSpanVerticalSlack(_ angle: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGFloat {
        let rotatedHeight = w * abs(sin(angle)) + h * abs(cos(angle))
        return max((rotatedHeight - h) / 2, 0)
    }
}
