import Foundation
import Supabase

public final class SupabaseManager {
    public static let shared = SupabaseManager()

    public let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rmolayttdgofyoshhzhm.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtb2xheXR0ZGdvZnlvc2hoemhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODk2NTYsImV4cCI6MjA5MjA2NTY1Nn0.f1_l4bOzBKfdK3vUbECIperYoTkH4Qk_YEWRPxfxQJ4"
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
