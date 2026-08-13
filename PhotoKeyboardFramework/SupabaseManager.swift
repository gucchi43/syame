import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()

    public let client: SupabaseClient

    /// 接続情報はビルド設定 (SUPABASE_URL / SUPABASE_ANON_KEY) からフレームワークの
    /// Info.plist を経由して渡す。ソースに直書きすると鍵のローテーションのたびに
    /// コード変更が必要になり、開発用と本番用のプロジェクトを分けることもできない。
    private static func configurationValue(for key: String) -> String {
        let bundle = Bundle(for: SupabaseManager.self)
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            // ビルド設定の指定漏れは起動直後に気付けるようにする
            fatalError("\(key) がビルド設定に定義されていません")
        }
        return value
    }

    private init() {
        let host = SupabaseManager.configurationValue(for: "SupabaseURL")
        guard let url = URL(string: "https://\(host)") else {
            fatalError("SUPABASE_URL が不正です: \(host)")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseManager.configurationValue(for: "SupabaseAnonKey"),
            // 保存済みセッションを起動直後のイベントとして流し、ネットワーク待ちで認証が止まらないようにする
            options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
        )
    }

    public var locale: String {
        Lang.rootKey()
    }

    public var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
