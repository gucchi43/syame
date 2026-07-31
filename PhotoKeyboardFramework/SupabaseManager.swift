import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()

    public let client: SupabaseClient

    /// 同時に複数のサインインが走らないよう、進行中のタスクを共有する
    private var signInTask: Task<UUID, Error>?
    private let signInLock = NSLock()

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

    /// 保存済みの認証ID。まだサインインが完了していない場合は nil。
    public var currentUserId: UUID? {
        return UUID(uuidString: GroupeDefaults.shared.authUid())
    }

    /// サインイン済みならそのIDを、未サインインなら匿名サインインしてIDを返す。
    /// 通信エラーとセッション未作成を区別するため、セッション欠如以外のエラーでは再サインインしない。
    /// 再サインインしてしまうと過去の投稿の所有権を失うため。
    @discardableResult
    public func ensureSignedIn() async throws -> UUID {
        signInLock.lock()
        if let task = signInTask {
            signInLock.unlock()
            return try await task.value
        }
        let task = Task<UUID, Error> { [client] in
            do {
                let session = try await client.auth.session
                return session.user.id
            } catch AuthError.sessionMissing {
                let session = try await client.auth.signInAnonymously()
                return session.user.id
            }
        }
        signInTask = task
        signInLock.unlock()

        do {
            let uid = try await task.value
            GroupeDefaults.shared.setAuthUid(id: uid.uuidString)
            return uid
        } catch {
            // 失敗したタスクを残すと以降ずっと同じエラーを返してしまうため破棄する
            signInLock.lock()
            signInTask = nil
            signInLock.unlock()
            throw error
        }
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
