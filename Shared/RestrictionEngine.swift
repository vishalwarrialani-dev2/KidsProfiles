import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

extension DeviceActivityName {
    static let kidDaily = Self("kidProfile.daily")
}

/// Applies a profile's rules device-wide and schedules the daily time limit.
/// Used by both the app and the monitor extension.
enum RestrictionEngine {
    static let store = ManagedSettingsStore()
    static let center = DeviceActivityCenter()

    /// Usage is recorded in steps of this many minutes.
    static let tickMinutes = 5
    static let limitEvent = "limit"
    static let tickPrefix = "tick."

    // MARK: Switching

    /// Switch the iPad to a kid profile.
    static func activate(_ profile: KidProfile) {
        Storage.activeProfileID = profile.id
        applyShields(for: profile)
        startMonitoring(profile)
    }

    /// Parent mode: remove every restriction.
    static func deactivate() {
        center.stopMonitoring([.kidDaily])
        store.clearAllSettings()
        Storage.activeProfileID = nil
    }

    // MARK: Shields and content rules

    static func applyShields(for profile: KidProfile) {
        store.clearAllSettings()

        let used = Storage.usedMinutes(for: profile.id)
        let timeIsUp = profile.dailyLimitMinutes > 0 && used >= profile.dailyLimitMinutes

        if timeIsUp {
            // Out of time: shield everything.
            store.shield.applicationCategories = .all()
            store.shield.webDomainCategories = .all()
        } else {
            // Allow-list: shield everything except what the parent picked.
            store.shield.applicationCategories = .all(except: profile.allowed.applicationTokens)
            store.shield.webDomainCategories = .all(except: profile.allowed.webDomainTokens)
        }

        if profile.filterAdultWeb {
            store.webContent.blockedByFilter = .auto()
        }
        if profile.blockExplicitMedia {
            store.media.denyExplicitContent = true
        }
        if profile.blockInstallsAndPurchases {
            store.application.denyAppInstallation = true
            store.appStore.denyInAppPurchases = true
        }
        // Stop a child from deleting this app to escape the rules.
        store.application.denyAppRemoval = true
    }

    // MARK: Daily time limit

    static func startMonitoring(_ profile: KidProfile) {
        center.stopMonitoring([.kidDaily])
        guard profile.dailyLimitMinutes > 0 else { return }

        let used = Storage.usedMinutes(for: profile.id)
        let remaining = profile.dailyLimitMinutes - used
        Storage.baseline = used
        Storage.monitoringDay = Storage.today

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        let hasTargets = !profile.allowed.applicationTokens.isEmpty
            || !profile.allowed.categoryTokens.isEmpty
            || !profile.allowed.webDomainTokens.isEmpty

        if remaining > 0 && hasTargets {
            func event(after minutes: Int) -> DeviceActivityEvent {
                DeviceActivityEvent(
                    applications: profile.allowed.applicationTokens,
                    categories: profile.allowed.categoryTokens,
                    webDomains: profile.allowed.webDomainTokens,
                    threshold: DateComponents(minute: minutes)
                )
            }
            // Progress ticks so usage survives a profile switch.
            var m = tickMinutes
            while m < remaining {
                events[.init("\(tickPrefix)\(m)")] = event(after: m)
                m += tickMinutes
            }
            // The limit itself.
            events[.init(limitEvent)] = event(after: remaining)
        }

        // Runs all day and repeats, so the extension is woken at midnight to reset.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            try center.startMonitoring(.kidDaily, during: schedule, events: events)
        } catch {
            print("KidProfiles: could not start monitoring: \(error)")
        }
    }

    // MARK: Called by the monitor extension

    static func handleEvent(_ name: String) {
        guard let profile = Storage.activeProfile else { return }
        if name == limitEvent {
            Storage.setUsedMinutes(profile.dailyLimitMinutes, for: profile.id)
            applyShields(for: profile)   // now shields everything
        } else if name.hasPrefix(tickPrefix), let m = Int(name.dropFirst(tickPrefix.count)) {
            let total = Storage.baseline + m
            if total > Storage.usedMinutes(for: profile.id) {
                Storage.setUsedMinutes(total, for: profile.id)
            }
        }
    }

    static func handleIntervalStart() {
        guard let profile = Storage.activeProfile else { return }
        // A new day began while this profile was active: usage is 0 again
        // (it is stored per day), so re-apply rules with a fresh limit.
        if Storage.monitoringDay != Storage.today {
            activate(profile)
        }
    }
}
