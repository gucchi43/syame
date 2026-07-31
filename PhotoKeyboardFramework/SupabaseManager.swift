import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()

    public let client: SupabaseClient

    /// 同時に複数のサインインが走らないよう、進行中のタスクを共有する
    private var signInTask: Task<UUID, Error>?
    private let signInLock = NSLock()

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rmolayttdgofyoshhzhm.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtb2xheXR0ZGdvZnlvc2hoemhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODk2NTYsImV4cCI6MjA5MjA2NTY1Nn0.f1_l4bOzBKfdK3vUbECIperYoTkH4Qk_YEWRPxfxQJ4",
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
