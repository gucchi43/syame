//
//  SecretCodeUnlock.swift
//  PhotoKeyboardEx
//

import Foundation
import CryptoKit

/// シークレットコードによる保存枚数の解放。
///
/// 課金(`PremiumStore`)とは別の経路で、関係者や招待した人に上限なしで使ってもらうためのもの。
/// プレミアムの表示(メニューの「ご利用中のプラン」など)には影響させず、上限の判定だけに効かせる。
///
/// **コードは平文でソースに置かない。** バイナリから文字列を抜かれても分からないよう、
/// 正規化した入力の SHA-256 と照合する。
///
/// 入口は設定画面の見出しを続けて叩く隠し操作にしている。
/// 独自の仕組みで機能を解放する入口が見えていると、審査ガイドライン 3.1.1 で指摘されうるため。
enum SecretCodeUnlock {

    /// 受け付けるコードの SHA-256(16進小文字)。正規化後の入力と比べる。
    /// リポジトリは公開なので、コードそのものはテストにも書かない
    static let acceptedDigests: Set<String> = [
        "94241ab7e33c38524950166e2a1aa0eb9c3d53a1fc33e35292b32531f1ff5390"
    ]

    private static let unlockedKey = "secretCodeUnlocked"

    /// 解放済みか。アプリ本体の UserDefaults に持つ。
    /// キーボード拡張は保存枚数を判定しないので App Group には置かない
    static func isUnlocked(defaults: UserDefaults = .standard) -> Bool {
        return defaults.bool(forKey: unlockedKey)
    }

    /// コードとして正しいか。前後の空白と大文字小文字の違いは許す
    static func isValid(_ input: String, accepted: Set<String> = acceptedDigests) -> Bool {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        let digest = SHA256.hash(data: Data(normalized.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return accepted.contains(hex)
    }

    /// 入力を照合し、正しければ解放して記録する。結果を返す
    @discardableResult
    static func redeem(_ input: String,
                       defaults: UserDefaults = .standard,
                       accepted: Set<String> = acceptedDigests) -> Bool {
        guard isValid(input, accepted: accepted) else { return false }
        // 上限は追加の入口と保存直前で毎回判定するので、記録するだけで次の追加から効く
        defaults.set(true, forKey: unlockedKey)
        return true
    }
}
