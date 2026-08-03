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

/// 公式LINEアカウントへの導線。
///
/// https://line.me/ti/p/... は一度Safariが開いてから転送されるため、
/// LINEがインストールされている場合は直接アプリを開くカスタムスキームを使う。
public enum OfficialLINE {
    private static let basicId = "%40gox9644r"

    /// LINEアプリを直接開く。インストールされていない場合は何も起きない
    public static var appURL: URL? {
        return URL(string: "line://ti/p/\(basicId)")
    }

    /// LINEが無い環境向け。/R/ はLINEがアプリを開くために用意しているパス
    public static var webURL: URL? {
        return URL(string: "https://line.me/R/ti/p/\(basicId)")
    }
}
