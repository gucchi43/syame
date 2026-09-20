//
//  OnboardingCoordinator.swift
//  PhotoKeyboardEx
//

import Foundation
import UIKit
import PhotoKeyboardFramework

/// 初回利用の手順。順番に意味がある。
enum OnboardingStep: Int, CaseIterable {
    /// 何ができるアプリかを知る
    case welcome
    /// 画像を1枚保存する
    case savePhoto
    /// キーボードを一覧に追加する
    case enableKeyboard
    /// フルアクセスを許可して、一度キーボードを開く
    case allowFullAccess
    /// 送り方を知る
    case howToSend
    /// すべて済んだ
    case done
}

/// いまどの手順にいるかを1箇所で決める。
enum OnboardingCoordinator {

    /// いまどの手順にいるかを決める。
    ///
    /// 判定は真偽フラグではなく**実際の状態**から導く。アプリの外で先に
    /// キーボードを有効にした人にも追従でき、既存の利用者も現在地に着地する。
    ///
    /// 上から順に見るので、先の手順が先に出ることはない。
    static func currentStep(hasSeenWelcome: Bool,
                            userOwnedPhotoCount: Int,
                            isKeyboardEnabled: Bool,
                            hasFullAccess: Bool = true,
                            hasSeenHowToSend: Bool) -> OnboardingStep {
        guard hasSeenWelcome else { return .welcome }
        // 見本は起動時に自動で入るため、自分で保存した枚数だけを見る。
        // 混ぜると1枚も入れていない人を素通りさせてしまう
        guard userOwnedPhotoCount > 0 else { return .savePhoto }
        // フルアクセスという重い許可は、価値を体験してから求める。
        //
        // 一覧に追加しただけでは終わりにしない。ペリペリはフルアクセスが無いと
        // 画像をコピーできず、まったく使えない。追加済みというだけで案内を止めると、
        // 一番肝心な設定が済んでいないのに何の案内も出ない状態になる。
        guard isKeyboardEnabled else { return .enableKeyboard }
        // 追加しただけでは使えない。フルアクセスまで確かめる
        guard hasFullAccess else { return .allowFullAccess }
        guard hasSeenHowToSend else { return .howToSend }
        return .done
    }

    /// 完了の祝いを出すべきか判定する。
    ///
    /// **最後の手順を終えた瞬間だけ**出す。達成感のピークで、実際に使ってみる気に
    /// なりやすいため。次の条件を全部満たしたときに限る。
    ///
    /// - まだ一度も出していない
    /// - いま完了した(`current == .done`)
    /// - 直前は完了していなかった
    ///
    /// `previous` が nil のとき(＝この端末で手順を観測したことがない)は出さない。
    /// 既に全部終わっている利用者がアップデートしただけで、脈絡のない
    /// ダイアログを見ることになる。
    static func shouldCelebrate(previous: OnboardingStep?,
                                current: OnboardingStep,
                                hasCelebrated: Bool) -> Bool {
        guard !hasCelebrated else { return false }
        guard current == .done else { return false }
        guard let previous = previous else { return false }
        return previous != .done
    }

    /// いまの端末の状態から現在地を出す
    @MainActor
    static var current: OnboardingStep {
        return currentStep(hasSeenWelcome: !GroupeDefaults.shared.isRegisterPush(),
                           userOwnedPhotoCount: RealmManager.shared.userOwnedPhotoCount,
                           isKeyboardEnabled: isKeyboardExtensionEnabled,
                           hasFullAccess: GroupeDefaults.shared.hasConfirmedFullAccess(),
                           hasSeenHowToSend: !GroupeDefaults.shared.isHowToSendPush())
    }

    /// 端末で有効になっているキーボードの一覧に拡張のバンドルIDがあるか。
    ///
    /// これは「一覧に追加されたか」しか分からない。フルアクセスの可否は別に見る。
    static var isKeyboardExtensionEnabled: Bool {
        let keyboards = UserDefaults.standard.array(forKey: "AppleKeyboards") as? [String] ?? []
        return keyboards.contains(GroupeDefaults.keyboardExtensionBundleId)
    }
}

extension OnboardingStep {
    /// ボードの上に常設で出す一行。モーダルは閉じたら消えるため、
    /// 「次に何をすればいいか」が画面に残り続けるようにする
    var hintKey: LocalizeKey? {
        switch self {
        case .welcome, .done: return nil
        case .savePhoto: return .onboardingHintSavePhoto
        case .enableKeyboard: return .onboardingHintEnableKeyboard
        case .allowFullAccess: return .onboardingHintAllowFullAccess
        case .howToSend: return .onboardingHintHowToSend
        }
    }
}
