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
    public static let saveCount = DefaultsKey<Int>("saveCount", defaultValue: 0)
}

public final class GroupeDefaults {
    fileprivate init() {
    }
    public static let shared = GroupeDefaults()
    
    public var sharedDefaults = UserDefaults(suiteName: "group.bocchi.PhotoKeyboardEx")!
    
    public func incrementSave() {
        sharedDefaults[.launchCount] += 1
    }
    
    public func isUsagePush() -> Bool {
        if sharedDefaults[.launchCount] == 0 {
            return true
        } else {
            return false
        }
    }
    
    public func isAddCount() -> Bool {
        if sharedDefaults[.saveCount] % 5 == 0 {
            return true
        } else {
            return false
        }
    }
    
}

