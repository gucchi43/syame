//
//  CommonUtil.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/09/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

//Localizableを呼び出せるようにする設定
public class CommonUtil
{
    public static let shared = CommonUtil()
    private init(){
        bundle = Bundle(for: type(of: self))
    }
    public let bundle: Bundle
}

extension String
{
    public var localized: String
    {
        let bundle = CommonUtil.shared.bundle
        let result = NSLocalizedString(self, tableName: "Localizable", bundle: bundle, value: "", comment: self)
        return result
    }
}
