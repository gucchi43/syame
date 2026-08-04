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
    /// App Group が利用できない環境でもクラッシュせず standard にフォールバックする(拡張とは共有されない)
    public let sharedDefaults = UserDefaults(suiteName: GroupeDefaults.appGroupIdentifier) ?? .standard

    private enum Keys: String {
        case authUid, launchCount, sendCount
        case usageNeedFlag, registerNeedFlag
        case blockContents
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

    public func authUid() -> String {
        return sharedDefaults.string(forKey: Keys.authUid.rawValue) ?? ""
    }
    public func setAuthUid(id: String) {
        sharedDefaults.set(id, forKey: Keys.authUid.rawValue)
    }

    public func isRegisterPush() -> Bool {
        if sharedDefaults.object(forKey: Keys.registerNeedFlag.rawValue) == nil {
            return true
        }
        return sharedDefaults.bool(forKey: Keys.registerNeedFlag.rawValue)
    }

    public func registerDone() {
        sharedDefaults.set(false, forKey: Keys.registerNeedFlag.rawValue)
    }

    public func isUsagePush() -> Bool {
        if sharedDefaults.object(forKey: Keys.usageNeedFlag.rawValue) == nil {
            return true
        }
        return sharedDefaults.bool(forKey: Keys.usageNeedFlag.rawValue)
    }

    public func usageDone() {
        sharedDefaults.set(false, forKey: Keys.usageNeedFlag.rawValue)
    }

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

    public func addBlockContents(id: String) {
        var list = sharedDefaults.stringArray(forKey: Keys.blockContents.rawValue) ?? []
        guard !list.contains(id) else { return }
        list.append(id)
        sharedDefaults.set(list, forKey: Keys.blockContents.rawValue)
    }

    public func getBlockContens() -> [String] {
        return sharedDefaults.stringArray(forKey: Keys.blockContents.rawValue) ?? []
    }
}
