//
//  DefaultsKeys.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

public final class GroupeDefaults {
    fileprivate init() {}
    public static let shared = GroupeDefaults()
    public var sharedDefaults = UserDefaults(suiteName: "group.bocchi.PhotoKeyboardEx")!

    private enum Keys: String {
        case authUid, launchCount, saveLife, sendCount
        case usageNeedFlag, welcomeNeedFlag, registerNeedFlag
        case blockContents
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

    public func isWelcomePush() -> Bool {
        if sharedDefaults.object(forKey: Keys.welcomeNeedFlag.rawValue) == nil {
            return true
        }
        return sharedDefaults.bool(forKey: Keys.welcomeNeedFlag.rawValue)
    }

    public func welcomeDone() {
        sharedDefaults.set(false, forKey: Keys.welcomeNeedFlag.rawValue)
    }

    public func incrementLaunchCount() {
        let count = sharedDefaults.integer(forKey: Keys.launchCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.launchCount.rawValue)
    }

    public func incrementSendCount() {
        let count = sharedDefaults.integer(forKey: Keys.sendCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.sendCount.rawValue)
    }

    public func isAddCount() -> Bool {
        let life = sharedDefaults.object(forKey: Keys.saveLife.rawValue) == nil ? 5 : sharedDefaults.integer(forKey: Keys.saveLife.rawValue)
        return life <= 0
    }

    public func useSaveLife() {
        let life = sharedDefaults.object(forKey: Keys.saveLife.rawValue) == nil ? 5 : sharedDefaults.integer(forKey: Keys.saveLife.rawValue)
        sharedDefaults.set(life - 1, forKey: Keys.saveLife.rawValue)
    }

    public func chargeSaveLife(amount: Int) {
        sharedDefaults.set(amount, forKey: Keys.saveLife.rawValue)
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
        list.append(id)
        sharedDefaults.set(list, forKey: Keys.blockContents.rawValue)
    }

    public func getBlockContens() -> [String] {
        return sharedDefaults.stringArray(forKey: Keys.blockContents.rawValue) ?? []
    }
}
