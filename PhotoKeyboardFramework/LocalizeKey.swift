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
    
    case doneUploadToast
    case myBoardEmptyTitle
    
    case menuHome
    case menuSetting
    case menuLine
    case menuOfficial

    case addNavTitle
    case addInputTitle
    case addInputGenre
    case subGenreMyBoard
    case subGenreNew
    case subGenrePopular
    case genreHumor
    case genreCool
    case genreCute
    case genreSerious
    case genreOther
    case addPublicSwitchOn
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
    
    case topHeadline
    case topSubtitle
    case topStart
    case topRequestFirst
    case topRequestSecond
    case topRequestThird
    case topRequestFourth
    case topRequestFifth
    case blockContent
    case cancel
    case menuCopy
    case menuDelete
    case menuDeleteConfirm
    case copiedToast
    
    
    //キーボード側
    case notFullButton
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
