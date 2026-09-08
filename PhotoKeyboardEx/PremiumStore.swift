//
//  PremiumStore.swift
//  PhotoKeyboardEx
//

import Foundation
import StoreKit

/// 課金状態と商品情報を持つ。
///
/// **アプリ本体にだけ置く。** `PhotoKeyboardFramework` はキーボード拡張とも共有されるため、
/// そこに課金コードを置くと拡張にも StoreKit が載る。拡張は Realm にあるものを表示するだけで
/// 課金状態を知らない、という方針に反し、拡張のメモリ上限にも不利。
///
/// **真実のソースは StoreKit。** App Group / UserDefaults / Realm には保存しない。
/// 共有コンテナの消失で課金が飛ぶ事故と、バックアップ経由の巻き戻しを防ぐ。
@MainActor
final class PremiumStore {

    static let shared = PremiumStore()

    /// 販売しているサブスクリプションの Product ID
    enum ProductID {
        static let monthly = "bocchi.PhotoKeyboardEx.premium.monthly"
        static let yearly = "bocchi.PhotoKeyboardEx.premium.yearly"
        static let all: Set<String> = [monthly, yearly]
    }

    /// プレミアムかどうか。トライアル中も true になる
    private(set) var isPremium = false

    /// 月額・年額。読み込み前は空
    private(set) var products: [Product] = []

    private var updatesTask: Task<Void, Never>?

    private init() {}

    /// 商品情報を取り込む。ペイウォールを出す前に呼ぶ
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: ProductID.all)
            // 月額・年額の順に固定する。並び順がストアの返り順で変わると
            // ペイウォールの上下が入れ替わって見える
            products = fetched.sorted { lhs, rhs in
                order(of: lhs.id) < order(of: rhs.id)
            }
        } catch {
            products = []
        }
    }

    private func order(of productID: String) -> Int {
        switch productID {
        case ProductID.monthly: return 0
        case ProductID.yearly: return 1
        default: return 2
        }
    }

    /// 現在の権利を数え直す
    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }
            premium = true
            break
        }
        setPremium(premium)
    }

    /// 購入する。購入が完了したら true
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// 購入の復元。機種変更や再インストールのため
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    /// アプリ外での購入・更新・返金を取りこぼさないよう、生存期間中ずっと監視する。
    /// 起動時に一度だけ呼ぶ
    func startObservingTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    private func setPremium(_ value: Bool) {
        guard isPremium != value else { return }
        isPremium = value
        NotificationCenter.default.post(name: .premiumStateChanged, object: nil)
    }
}
