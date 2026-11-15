import Foundation

/// Must match the App Group in both targets' entitlements.
let appGroupID = "group.com.example.kidprofiles"

/// Small persistence layer in the shared App Group, so the app and the
/// background monitor extension see the same data.
enum Storage {
    static let defaults = UserDefaults(suiteName: appGroupID) ?? .standard

    // MARK: Profiles

    static func loadProfiles() -> [KidProfile] {
        guard let data = defaults.data(forKey: "profiles"),
              let list = try? JSONDecoder().decode([KidProfile].self, from: data) else { return [] }
        return list
    }

    static func saveProfiles(_ profiles: [KidProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: "profiles")
        }
    }

    static var activeProfileID: UUID? {
        get { defaults.string(forKey: "activeProfileID").flatMap(UUID.init(uuidString:)) }
        set { defaults.set(newValue?.uuidString, forKey: "activeProfileID") }
    }

    static var activeProfile: KidProfile? {
        guard let id = activeProfileID else { return nil }
        return loadProfiles().first { $0.id == id }
    }

    // MARK: Daily usage (minutes), stored per profile per calendar day

    static var today: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private static func usageKey(_ id: UUID) -> String { "used.\(today).\(id.uuidString)" }

    static func usedMinutes(for id: UUID) -> Int { defaults.integer(forKey: usageKey(id)) }

    static func setUsedMinutes(_ minutes: Int, for id: UUID) {
        defaults.set(minutes, forKey: usageKey(id))
    }

    /// Minutes the active profile had already used when monitoring was (re)started.
    static var baseline: Int {
        get { defaults.integer(forKey: "baseline") }
        set { defaults.set(newValue, forKey: "baseline") }
    }

    /// The day monitoring was last (re)started, used to detect midnight rollover.
    static var monitoringDay: String {
        get { defaults.string(forKey: "monitoringDay") ?? "" }
        set { defaults.set(newValue, forKey: "monitoringDay") }
    }
}
