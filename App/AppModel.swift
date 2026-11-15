import SwiftUI
import FamilyControls

@MainActor
final class AppModel: ObservableObject {
    @Published var profiles: [KidProfile] = Storage.loadProfiles()
    @Published var activeID: UUID? = Storage.activeProfileID
    @Published var unlocked = false
    @Published var hasPIN = ParentPIN.isSet
    @Published var authorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @Published var authError: String?

    var activeProfile: KidProfile? { profiles.first { $0.id == activeID } }

    func refresh() {
        activeID = Storage.activeProfileID
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        objectWillChange.send()   // re-read usage minutes
    }

    /// Asks iPadOS for Screen Time access. Needed once, on a real iPad.
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = true
            authError = nil
        } catch {
            authorized = false
            authError = error.localizedDescription
        }
    }

    // MARK: Profiles

    func save(_ profile: KidProfile) {
        if let i = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[i] = profile
        } else {
            profiles.append(profile)
        }
        Storage.saveProfiles(profiles)
    }

    func delete(_ profile: KidProfile) {
        if activeID == profile.id { parentMode() }
        profiles.removeAll { $0.id == profile.id }
        Storage.saveProfiles(profiles)
    }

    // MARK: Switching

    func start(_ profile: KidProfile) {
        RestrictionEngine.activate(profile)
        activeID = profile.id
        unlocked = false
    }

    func parentMode() {
        RestrictionEngine.deactivate()
        activeID = nil
    }

    // MARK: Usage

    func usedToday(_ profile: KidProfile) -> Int { Storage.usedMinutes(for: profile.id) }

    func resetUsage(_ profile: KidProfile) {
        Storage.setUsedMinutes(0, for: profile.id)
        if activeID == profile.id { RestrictionEngine.activate(profile) }
        objectWillChange.send()
    }
}
