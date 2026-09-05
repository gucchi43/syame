//
//  LocalizeKey.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/09/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation

public enum LocalizeKey: String, CaseIterable {
    
    case baseOK
    case baseCancel
    
    case navMyBoard
    
    case doneSaveToast
    case myBoardEmptyTitle
    
    case menuHome
    case menuSetting

    case addNavTitle
    case addInputTitle
    case addDone
    
    case settingTitle
    case settingFirstBoaldText
    case settingFirstNormalText
    case settingSecondBoaldText
    case settingSecondNormalText
    case settingThirdBoaldText
    case settingThirdNormalText
    case settingDiscription
    case settingDone
    case settingLater
    case limitReachedTitle
    case limitReachedMessage

    // 送り方の案内
    case howToTitle
    case howToFirstBoldText
    case howToFirstNormalText
    case howToSecondBoldText
    case howToSecondNormalText
    case howToThirdBoldText
    case howToThirdNormalText
    case howToDescription
    case howToDone
    case menuHowTo
    
    case topHeadline
    case topSubtitle
    case topStart
    case topRequestFirst
    case topRequestSecond
    case topRequestThird
    case topRequestFourth
    case topRequestFifth
    case menuCopy
    case menuDelete
    case menuDeleteConfirm
    case copiedToast
    
    
    //キーボード側
    case notFullButton
    case notFullGuide
    case addPhotoFromApp

    case updateAlertTitle
    case updateAlertMessage
    case updateAlertUpdate
    case updateAlertLater

    // selfの値をローカライズして返す
    public func localizedString() -> String {
        
        let bundle = CommonUtil.shared.bundle
        let result = NSLocalizedString(self.rawValue, tableName: "Localizable", bundle: bundle, value: "", comment: "")
        return result
    }
}
