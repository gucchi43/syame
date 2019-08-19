//
//  ColorMG.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/08.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor

import UIKit

extension UIColor {
     public class func bgDark() -> UIColor{
        return UIColor.init(hexString: "240440")
    }
    
    public class func acGreen() -> UIColor{
        return UIColor.init(hexString: "26F78E")
    }
    
    public class func acPink() -> UIColor{
        return UIColor.init(hexString: "f7268f")
    }
    
    //既存のよくあるボタンの水色のやつ
     public class func defaultButtonColor() -> UIColor { //skyBuleColor
        return UIColor(red: 19/255.0, green:144/255.0, blue:255/255.0, alpha:1.0)
        
    }
}

