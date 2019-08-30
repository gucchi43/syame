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
    public static let launchCount = DefaultsKey<Int>("launchCount", defaultValue: 0)
    public static let saveLife = DefaultsKey<Int>("saveCount", defaultValue: 5)
    public static let usageNeed = DefaultsKey<Bool>("usageFlag", defaultValue: true)
}

public final class GroupeDefaults {
    fileprivate init() {
    }
    public static let shared = GroupeDefaults()
    public var sharedDefaults = UserDefaults(suiteName: "group.bocchi.PhotoKeyboardEx")!

    public func isUsagePush() -> Bool {
        if sharedDefaults[.usageNeed] {
            return true
        } else {
            return false
        }
    }
    
    public func usageDone() {
        sharedDefaults[.usageNeed] = false
    }
    
    public func incrementLaunchCount() {
        sharedDefaults[.launchCount] += 1
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
}

