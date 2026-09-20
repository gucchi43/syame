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

    /// 案内図の中に出す短い語。手順の文言(howTo*)は既存のものを使い、
    /// 図の上に重ねるこの2語だけを持つ
    case guideCopyBadge
    case guidePasteBadge
    
    case topHeadline
    case topSubtitle
    case topSubtitleSecond
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

    // MARK: - 有料プラン

    case paywallTitle
    case paywallSubtitle
    case paywallFeatureUnlimited
    case paywallColumnFree
    case paywallColumnPremium
    case paywallRowSaveCount
    case paywallFreeLimitValue
    case paywallUnlimitedValue
    case paywallPlanMonthly
    case paywallPlanYearly
    case paywallYearlyPerMonth
    case paywallYearlyDiscount
    case paywallTrialBadge
    case paywallPurchase
    case paywallPurchaseWithTrial
    case paywallRestore
    case paywallRetry
    case paywallPurchasePending
    case paywallTerms
    case paywallPrivacy
    case paywallRenewalNote
    case paywallSeePremium
    case paywallClose
    case paywallPurchaseFailed
    case paywallRestoreFailed
    case paywallRestoreNothing
    case heroTapAndPaste
    case keyboardTextMode
    case chatIncomingFirst
    case chatIncomingSecond
    case sampleTitleCat
    case sampleTitleFood
    case sampleTitleTown
    case onboardingHintSavePhoto
    case onboardingHintEnableKeyboard
    case onboardingHintHowToSend
    case menuPremium
    case menuPremiumActive
    case premiumActiveTitle
    case premiumActiveMessage

    /// 数値などを差し込む文言に使う。書式は Localizable.strings 側が持つ
    public func localizedString(_ arguments: CVarArg...) -> String {
        return String(format: localizedString(), arguments: arguments)
    }

    // selfの値をローカライズして返す
    public func localizedString() -> String {
        
        let bundle = CommonUtil.shared.bundle
        let result = NSLocalizedString(self.rawValue, tableName: "Localizable", bundle: bundle, value: "", comment: "")
        return result
    }
}
