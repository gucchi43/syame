//
//  PhotoQuota.swift
//  PhotoKeyboardEx
//

import Foundation
import PhotoKeyboardFramework

/// 保存枚数の上限判定を1箇所に集める。
///
/// 課金状態はアプリ本体しか知らないため、フレームワーク側の `RealmManager` だけでは
/// 判断できない。無料枠の定義は `RealmManager` に残したまま、課金による解除をここで被せる。
@MainActor
enum PhotoQuota {

    /// あと1枚保存できるか。プレミアムなら常に true
    static var canSave: Bool {
        if PremiumStore.shared.isPremium { return true }
        return RealmManager.shared.canSaveMorePhotos
    }

    /// 無料で保存できる枚数。ペイウォールと上限アラートの文言に出す
    static var freeLimit: Int {
        return RealmManager.photoLimit
    }
}
