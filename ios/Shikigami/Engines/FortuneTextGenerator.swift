import Foundation

// docs/local-first-migration.md に定義されたプロトコル。
// ClaudeClient と同一シグネチャのため typealias で統一する。
// LocalFortuneGenerator と SupabaseClaudeClient の両方がこのプロトコルを実装する。
typealias FortuneTextGenerator = ClaudeClient
