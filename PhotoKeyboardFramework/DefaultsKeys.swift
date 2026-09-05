//
//  DefaultsKeys.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation

public final class GroupeDefaults {
    fileprivate init() {}
    public static let shared = GroupeDefaults()
    public static let appGroupIdentifier = "group.bocchi.PhotoKeyboardEx"
    /// キーボード拡張(PhotoKeyboardExOrigin)のバンドルID。
    /// 有効化検知(AppleKeyboards との突合)と os_log の subsystem の両方で使う共有の値
    public static let keyboardExtensionBundleId = "bocchi.PhotoKeyboardEx.PhotoKeyboardExOrigin"
    /// App Group が利用できない環境でもクラッシュせず standard にフォールバックする(拡張とは共有されない)
    public let sharedDefaults = UserDefaults(suiteName: GroupeDefaults.appGroupIdentifier) ?? .standard

    private enum Keys: String {
        case launchCount, sendCount, keyboardColumns
        case usageNeedFlag, registerNeedFlag, howToSendNeedFlag
        case lastKeyboardOpenResult
    }

    /// キーボード拡張はデバッガを繋ぎにくいため、URLオープンの結果だけApp Group経由で
    /// アプリ側に渡し、起動時のログで確認できるようにする
    public func setLastKeyboardOpenResult(_ result: String) {
        sharedDefaults.set(result, forKey: Keys.lastKeyboardOpenResult.rawValue)
    }

    public func lastKeyboardOpenResult() -> String? {
        return sharedDefaults.string(forKey: Keys.lastKeyboardOpenResult.rawValue)
    }

    /// キーボードの列数。未設定なら 0 が返るため、その場合は既定の3を返す。
    public func keyboardColumns() -> Int {
        let stored = sharedDefaults.integer(forKey: Keys.keyboardColumns.rawValue)
        return stored > 0 ? stored : GroupeDefaults.defaultKeyboardColumns
    }

    public func setKeyboardColumns(_ columns: Int) {
        sharedDefaults.set(columns, forKey: Keys.keyboardColumns.rawValue)
    }

    public static let defaultKeyboardColumns = 3
    public static let denseKeyboardColumns = 5

    /// 一度きりの案内フラグの共通実装。未設定(nil)なら「まだ案内していない」= true とみなす
    private func isPending(_ key: Keys) -> Bool {
        if sharedDefaults.object(forKey: key.rawValue) == nil {
            return true
        }
        return sharedDefaults.bool(forKey: key.rawValue)
    }

    private func markDone(_ key: Keys) {
        sharedDefaults.set(false, forKey: key.rawValue)
    }

    public func isRegisterPush() -> Bool { isPending(.registerNeedFlag) }
    public func registerDone() { markDone(.registerNeedFlag) }

    public func isUsagePush() -> Bool { isPending(.usageNeedFlag) }
    public func usageDone() { markDone(.usageNeedFlag) }

    /// 「送り方」の案内をまだ出していないか。キーボードの有効化を初めて検知したときに一度だけ出す
    public func isHowToSendPush() -> Bool { isPending(.howToSendNeedFlag) }
    public func howToSendDone() { markDone(.howToSendNeedFlag) }

    public func incrementLaunchCount() {
        let count = sharedDefaults.integer(forKey: Keys.launchCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.launchCount.rawValue)
    }

    public func incrementSendCount() {
        let count = sharedDefaults.integer(forKey: Keys.sendCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.sendCount.rawValue)
    }

    public func isRateAlert() -> Bool {
        let count = sharedDefaults.integer(forKey: Keys.sendCount.rawValue)
        if count > 7 {
            sharedDefaults.set(0, forKey: Keys.sendCount.rawValue)
            return true
        }
        return false
    }
}
