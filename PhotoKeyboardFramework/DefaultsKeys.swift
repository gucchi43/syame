//
//  DefaultsKeys.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation

public final class GroupeDefaults {
    fileprivate init() {}
    public static let shared = GroupeDefaults()
    public static let appGroupIdentifier = "group.bocchi.PhotoKeyboardEx"
    /// キーボード拡張(PhotoKeyboardExOrigin)のバンドルID。
    /// 有効化検知(AppleKeyboards との突合)と os_log の subsystem の両方で使う共有の値
    public static let keyboardExtensionBundleId = "bocchi.PhotoKeyboardEx.PhotoKeyboardExOrigin"
    /// App Group が利用できない環境でもクラッシュせず standard にフォールバックする(拡張とは共有されない)
    public let sharedDefaults = UserDefaults(suiteName: GroupeDefaults.appGroupIdentifier) ?? .standard

    private enum Keys: String {
        case launchCount, sendCount, keyboardColumns
        case usageNeedFlag, registerNeedFlag, howToSendNeedFlag
        case lastKeyboardOpenResult
        case seededOfficialPhotoIds
        case lastOnboardingStep, hasCelebratedOnboarding
        case fullAccessConfirmedAt
    }

    /// キーボード拡張はデバッガを繋ぎにくいため、URLオープンの結果だけApp Group経由で
    /// アプリ側に渡し、起動時のログで確認できるようにする
    public func setLastKeyboardOpenResult(_ result: String) {
        sharedDefaults.set(result, forKey: Keys.lastKeyboardOpenResult.rawValue)
    }

    public func lastKeyboardOpenResult() -> String? {
        return sharedDefaults.string(forKey: Keys.lastKeyboardOpenResult.rawValue)
    }

    /// キーボードの列数。未設定なら 0 が返るため、その場合は既定の3を返す。
    public func keyboardColumns() -> Int {
        let stored = sharedDefaults.integer(forKey: Keys.keyboardColumns.rawValue)
        return stored > 0 ? stored : GroupeDefaults.defaultKeyboardColumns
    }

    public func setKeyboardColumns(_ columns: Int) {
        sharedDefaults.set(columns, forKey: Keys.keyboardColumns.rawValue)
    }

    public static let defaultKeyboardColumns = 3
    public static let denseKeyboardColumns = 5

    /// 一度きりの案内フラグの共通実装。未設定(nil)なら「まだ案内していない」= true とみなす
    private func isPending(_ key: Keys) -> Bool {
        if sharedDefaults.object(forKey: key.rawValue) == nil {
            return true
        }
        return sharedDefaults.bool(forKey: key.rawValue)
    }

    private func markDone(_ key: Keys) {
        sharedDefaults.set(false, forKey: key.rawValue)
    }

    public func isRegisterPush() -> Bool { isPending(.registerNeedFlag) }
    public func registerDone() { markDone(.registerNeedFlag) }

    public func isUsagePush() -> Bool { isPending(.usageNeedFlag) }
    public func usageDone() { markDone(.usageNeedFlag) }

    /// 「送り方」の案内をまだ出していないか。キーボードの有効化を初めて検知したときに一度だけ出す
    public func isHowToSendPush() -> Bool { isPending(.howToSendNeedFlag) }
    public func howToSendDone() { markDone(.howToSendNeedFlag) }

    /// 投入済みの見本画像のID。
    ///
    /// Realm に在るかどうかで判定すると、利用者が見本を消しても起動のたびに戻ってきてしまう。
    /// 「配ったことがあるか」はRealmの中身とは別に持つ。
    public func hasSeededOfficialPhoto(id: String) -> Bool {
        let seeded = sharedDefaults.stringArray(forKey: Keys.seededOfficialPhotoIds.rawValue) ?? []
        return seeded.contains(id)
    }

    public func markOfficialPhotoSeeded(id: String) {
        var seeded = sharedDefaults.stringArray(forKey: Keys.seededOfficialPhotoIds.rawValue) ?? []
        guard !seeded.contains(id) else { return }
        seeded.append(id)
        sharedDefaults.set(seeded, forKey: Keys.seededOfficialPhotoIds.rawValue)
    }

    /// 直前に観測したオンボーディングの手順。
    /// 「いま完了した」を「ずっと完了している」と区別するために持つ
    public func lastOnboardingStep() -> Int? {
        guard sharedDefaults.object(forKey: Keys.lastOnboardingStep.rawValue) != nil else { return nil }
        return sharedDefaults.integer(forKey: Keys.lastOnboardingStep.rawValue)
    }

    public func setLastOnboardingStep(_ value: Int) {
        sharedDefaults.set(value, forKey: Keys.lastOnboardingStep.rawValue)
    }

    /// 完了の祝いを出したか。出すのは一度きり
    public func hasCelebratedOnboarding() -> Bool {
        return sharedDefaults.bool(forKey: Keys.hasCelebratedOnboarding.rawValue)
    }

    public func markOnboardingCelebrated() {
        sharedDefaults.set(true, forKey: Keys.hasCelebratedOnboarding.rawValue)
    }

    /// キーボード拡張がフルアクセスありで動いたことを記録する。
    ///
    /// **拡張はフルアクセスが無いと App Group へ書き込めない。**
    /// だから「ここに書けた」こと自体が、許可されている証拠になる。
    /// アプリ本体からフルアクセスの可否を直接問い合わせる方法は無い。
    public func markFullAccessConfirmed() {
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: Keys.fullAccessConfirmedAt.rawValue)
    }

    /// フルアクセスありで拡張が動いたことがあるか。
    ///
    /// 一度も使っていなければ false のままで、案内は出続ける。
    /// 「追加しただけで使えない」状態を見逃すより、使うまで案内が残る方がよい。
    /// なお許可を後から外された場合、この記録は残ったままになる。
    /// その状態はキーボード自身が `hasFullAccess` をその場で見て
    /// 専用の案内(notFullBGView)を出すため、本体の案内行では扱わない。
    public func hasConfirmedFullAccess() -> Bool {
        return sharedDefaults.object(forKey: Keys.fullAccessConfirmedAt.rawValue) != nil
    }

    public func incrementLaunchCount() {
        let count = sharedDefaults.integer(forKey: Keys.launchCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.launchCount.rawValue)
    }

    public func incrementSendCount() {
        let count = sharedDefaults.integer(forKey: Keys.sendCount.rawValue)
        sharedDefaults.set(count + 1, forKey: Keys.sendCount.rawValue)
    }

    public func isRateAlert() -> Bool {
        let count = sharedDefaults.integer(forKey: Keys.sendCount.rawValue)
        if count > 7 {
            sharedDefaults.set(0, forKey: Keys.sendCount.rawValue)
            return true
        }
        return false
    }
}
