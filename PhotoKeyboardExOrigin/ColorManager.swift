//
//  ColorManager.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/08/01.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor

final class ColorManager {
    fileprivate init() {
    }
    static let shared = ColorManager()
    
    func acRandom() -> UIColor {
        let greenHex = "#7af97d"
        let pinkHex = "#f4b5dc"
        let redHex = "#e24747"
        let yellowHex = "#ffffa4"
        let blueHex = "#63c6f7"
        let hexArray = [greenHex, pinkHex, redHex, yellowHex, blueHex]
        let selectHex = hexArray.randomElement()
        
        return UIColor(hexString: selectHex!)
    }
}

