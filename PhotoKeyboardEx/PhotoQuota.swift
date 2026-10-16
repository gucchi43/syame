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

    /// 上限なしで保存できるか。プレミアムかシークレットコードで解放済みなら true
    static var isUnlimited: Bool {
        return PremiumStore.shared.isPremium || SecretCodeUnlock.isUnlocked()
    }

    /// あと1枚保存できるか。上限なしなら常に true
    static var canSave: Bool {
        if isUnlimited { return true }
        return RealmManager.shared.canSaveMorePhotos
    }

    /// 無料で保存できる枚数。ペイウォールと上限アラートの文言に出す
    static var freeLimit: Int {
        return RealmManager.photoLimit
    }
}
