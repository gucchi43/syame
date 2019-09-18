//
//  LocalizeKey.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/09/11.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

public enum LocalizeKey: String {
    
    case baseOK
    case baseCancel
    
    case tabMyBoard
    case tabNew
    case tabPopular
    case tabHumor
    case tabCool
    case tabCute
    case tabSerious
    case tabOther
    
    case navMyBoard
    case navNew
    case navPopular
    case navHumor
    case navCool
    case navCute
    case navSerious
    case navOther
    
    case doneUploadToast
    case othersEmptyTitle
    case myBoardEmptyTitle
    case adAlertTitle
    case adAlertMessage
    
    case menuHome
    case menuSetting
    case menuLine
    case menuOfficial
    case menuOther
    
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
    
    case welcomeTitle
    case welcomeFirst1
    case welcomeFirst2
    case welcomeFirst3
    case welcomeSecond1
    case welcomeSecond2
    case welcomeSecond3
    case welcomeThird1
    case welcomeThird2
    case welcomeThird3
    case welcomeFourth
    case welcomeDiscriptionFirst
    case welcomeDiscriptionSecond
    case welcomeDiscriptionThird
    case welcomeDone
    case welcomeSkip
    //キーボード側
    case notFullButton
    case notFullLabelFirst
    case notFullLabelSecond
    case notFullLabelThird
    case notFullLabelFourth
    case notFullLabelFifth

    // selfの値をローカライズして返す
    public func localizedString() -> String {
        
        let bundle = CommonUtil.shared.bundle
        let result = NSLocalizedString(self.rawValue, tableName: "Localizable", bundle: bundle, value: "", comment: "")
        return result
    }
}
