//
//  BoardSlots.swift
//  PhotoKeyboardEx
//
//  マイボードに並べるマスの種類と並びを決める。Realm も UIKit も知らない。
//

import Foundation

/// マイボードの 1 マス
enum BoardSlot: Equatable {
    /// 保存済みの写真。index は realmData の添字
    case photo(index: Int)
    /// まだ埋まっていないマス。押すと追加へ
    case empty
}

enum BoardSlots {
    /// 写真の枚数と上限から、並べるマスを決める。
    ///
    /// 上限に満たないぶんは空きスロットで埋め、常に上限ぶんのマスを見せる。
    /// 上限を超えて保存されている場合は写真を優先して全部出す
    /// (上限を下げたあとの既存利用者の写真を隠さない)。
    static func make(photoCount: Int, limit: Int) -> [BoardSlot] {
        let photos = (0..<max(photoCount, 0)).map { BoardSlot.photo(index: $0) }
        let empties = Array(repeating: BoardSlot.empty, count: max(limit - photoCount, 0))
        return photos + empties
    }

    /// 直前の一覧に無かった写真の添字。保存直後に「ぽんと出す」マスを決める。
    /// 通知は id を持たないため、前後の id の差で見つける
    static func newlyAdded(previous: Set<String>, current: [String]) -> [Int] {
        return current.enumerated().compactMap { previous.contains($0.element) ? nil : $0.offset }
    }

    /// 上限まで埋まった瞬間に一度だけ祝う
    static func shouldCelebrate(filled: Int, limit: Int, hasCelebrated: Bool) -> Bool {
        return !hasCelebrated && filled >= limit
    }
}
