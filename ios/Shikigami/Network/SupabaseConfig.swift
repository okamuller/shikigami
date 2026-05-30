import Foundation

// Supabase 接続情報
// 値は Config.xcconfig（gitignore 対象）の SUPABASE_URL / SUPABASE_ANON_KEY から読み込む
// 未設定時はプレースホルダーを返す（local-first ビルドでクラッシュしないよう fatalError を除去）
enum SupabaseConfig {
    static var url: URL {
        if let raw = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://placeholder.supabase.co")!
    }

    static var anonKey: String {
        (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String) ?? ""
    }
}
