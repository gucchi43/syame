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

    /// 起動直後の権利判定が一度でも終わったか。
    /// 終わる前は「無料」ではなく「未確定」で、上限の判定に使うと
    /// 加入者に上限アラートを出してしまう
    private(set) var hasResolvedEntitlements = false

    /// 購入の結果。呼び出し側が利用者へ何を伝えるか決めるために区別する
    enum PurchaseOutcome {
        case purchased
        case cancelled
        /// 承認待ち(ファミリー共有の「承認と購入のリクエスト」など)
        case pending
        /// 署名を検証できなかった
        case unverified
    }

    private var updatesTask: Task<Void, Never>?

    private init() {}

    /// 商品情報を取り込む。ペイウォールを出す前に呼ぶ。
    /// 失敗は握り潰さない。呼び出し側が再試行の導線を出せるように投げる
    func loadProducts() async throws {
        let fetched = try await Product.products(for: ProductID.all)
        // 月額・年額の順に固定する。並び順がストアの返り順で変わると
        // ペイウォールの上下が入れ替わって見える
        products = fetched.sorted { lhs, rhs in
            order(of: lhs.id) < order(of: rhs.id)
        }
    }

    /// この利用者が無料トライアルを受けられるか。
    ///
    /// `product.subscription?.introductoryOffer` は商品に設定があるかを表すだけで、
    /// 利用者が使い切ったかどうかを反映しない。これで文言を出し分けると、
    /// 消化済みの人に「無料ではじめる」と見せて即課金することになる(審査 3.1.2 のリスク)。
    /// 資格はグループ単位なので、月額で使うと年額でも消える。
    func isEligibleForIntroductoryOffer(_ product: Product) async -> Bool {
        guard let subscription = product.subscription,
              subscription.introductoryOffer != nil else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    private func order(of productID: String) -> Int {
        switch productID {
        case ProductID.monthly: return 0
        case ProductID.yearly: return 1
        default: return 2
        }
    }

    /// 起動直後などで権利がまだ確定していなければ、確定させてから返る
    func ensureEntitlementsResolved() async {
        guard !hasResolvedEntitlements else { return }
        await refreshEntitlements()
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
        hasResolvedEntitlements = true
        setPremium(premium)
    }

    /// 購入する
    @discardableResult
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await refreshEntitlements()
                return .purchased
            case .unverified(let transaction, _):
                // finish しないと Transaction.updates に延々と再配信される
                await transaction.finish()
                return .unverified
            }
        case .userCancelled:
            return .cancelled
        case .pending:
            // 承認待ち。承認されたら Transaction.updates 側で拾う
            return .pending
        @unknown default:
            return .cancelled
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
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self?.refreshEntitlements()
                case .unverified(let transaction, _):
                    // 検証できないものも finish する。放置すると再配信され続ける
                    await transaction.finish()
                }
            }
        }
    }

    private func setPremium(_ value: Bool) {
        guard isPremium != value else { return }
        isPremium = value
        NotificationCenter.default.post(name: .premiumStateChanged, object: nil)
    }
}
