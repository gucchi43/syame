//
//  DefaultsKeys.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

extension DefaultsKeys {
    public static let authUid = DefaultsKey<String>("authUid", defaultValue: "")
    public static let launchCount = DefaultsKey<Int>("launchCount", defaultValue: 0)
    public static let saveLife = DefaultsKey<Int>("saveLife", defaultValue: 5)
    public static let sendCount = DefaultsKey<Int>("sendCount", defaultValue: 0)
    public static let usageNeedFlag = DefaultsKey<Bool>("usageNeedFlag", defaultValue: true)
    public static let welcomeNeedFlag = DefaultsKey<Bool>("welcomeNeedFlag", defaultValue: true)
}

public final class GroupeDefaults {
    fileprivate init() {
    }
    public static let shared = GroupeDefaults()
    public var sharedDefaults = UserDefaults(suiteName: "group.bocchi.PhotoKeyboardEx")!

    public func authUid() -> String {
        return sharedDefaults[.authUid]
    }
    public func setAuthUid(id: String) {
        sharedDefaults[.authUid] = id
    }
    
    public func isUsagePush() -> Bool {
        if sharedDefaults[.usageNeedFlag] {
            return true
        } else {
            return false
        }
    }
    
    public func usageDone() {
        sharedDefaults[.usageNeedFlag] = false
    }
    
    public func isWelcomePush() -> Bool {
        if sharedDefaults[.welcomeNeedFlag] {
            return true
        } else {
            return false
        }
    }
    
    public func welcomeDone() {
        sharedDefaults[.welcomeNeedFlag] = false
    }
    
    public func incrementLaunchCount() {
        sharedDefaults[.launchCount] += 1
    }
    
    public func incrementSendCount() {
        sharedDefaults[.sendCount] += 1
    }
    
    public func isAddCount() -> Bool {
        if sharedDefaults[.saveLife] > 0 {
            return false
        } else {
            return true
        }
    }
    
    public func useSaveLife() {
        sharedDefaults[.saveLife] -= 1
    }
    
    public func chargeSaveLife(amount: Int) {
        sharedDefaults[.saveLife] = amount
    }
    
    public func isRateAlert() -> Bool {
        if sharedDefaults[.sendCount] > 7 {
            sharedDefaults[.sendCount] = 0
            return true
        } else {
            return false
        }
    }
}

