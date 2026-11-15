import Foundation
import FamilyControls

/// One child's rule set. The parent ("master") has no profile: parent mode = no restrictions.
struct KidProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String = ""
    var emoji: String = "🧒"

    /// Apps / websites this child MAY use. Everything else is shielded.
    /// includeEntireCategory makes a whole-category pick expand to its individual apps.
    var allowed = FamilyActivitySelection(includeEntireCategory: true)

    /// Total minutes per day across the allowed apps. 0 = no time limit.
    var dailyLimitMinutes: Int = 60

    var filterAdultWeb = true
    var blockExplicitMedia = true
    var blockInstallsAndPurchases = true
}
