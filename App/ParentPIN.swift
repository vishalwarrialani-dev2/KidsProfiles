import Foundation
import CryptoKit

/// Parent PIN, stored only as a salted hash inside the app's private storage.
enum ParentPIN {
    private static let hashKey = "parentPIN.hash"
    private static let saltKey = "parentPIN.salt"
    private static var defaults: UserDefaults { .standard }

    static var isSet: Bool { defaults.string(forKey: hashKey) != nil }

    static func set(_ pin: String) {
        let salt = UUID().uuidString
        defaults.set(salt, forKey: saltKey)
        defaults.set(hash(pin, salt: salt), forKey: hashKey)
    }

    static func check(_ pin: String) -> Bool {
        guard let salt = defaults.string(forKey: saltKey),
              let stored = defaults.string(forKey: hashKey) else { return false }
        return hash(pin, salt: salt) == stored
    }

    private static func hash(_ pin: String, salt: String) -> String {
        SHA256.hash(data: Data((salt + pin).utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
