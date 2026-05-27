import Foundation
import SwiftData

// docs/design.md §4 データモデル準拠。ローカルユーザープロファイルを SwiftData に保存する。
@Model
final class UserProfile {
    var localUserId: UUID
    var birthDate: Date
    var gender: String
    var shikigamiId: Int

    init(localUserId: UUID, birthDate: Date, gender: String, shikigamiId: Int) {
        self.localUserId = localUserId
        self.birthDate = birthDate
        self.gender = gender
        self.shikigamiId = shikigamiId
    }
}
