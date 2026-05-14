import Foundation

// Supabase 接続情報
// 値は Config.xcconfig（gitignore 対象）の SUPABASE_URL / SUPABASE_ANON_KEY から読み込む
// Xcode Build Settings: Info.plist に $(SUPABASE_URL) / $(SUPABASE_ANON_KEY) を追加すること
enum SupabaseConfig {
    static var url: URL {
        guard let raw = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: raw)
        else { fatalError("SUPABASE_URL not configured in Info.plist") }
        return url
    }

    static var anonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String
        else { fatalError("SUPABASE_ANON_KEY not configured in Info.plist") }
        return key
    }
}
