import SwiftUI
import FamilyControls

struct ParentDashboard: View {
    @EnvironmentObject var model: AppModel
    @State private var editing: KidProfile?

    var body: some View {
        NavigationStack {
            List {
                if !model.authorized {
                    Section {
                        Button("Allow Screen Time access") {
                            Task { await model.requestAuthorization() }
                        }
                        if let e = model.authError {
                            Text(e).font(.footnote).foregroundStyle(.red)
                        }
                    } footer: {
                        Text("Restrictions cannot work until this is allowed.")
                    }
                }

                Section("Now using the iPad") {
                    if let p = model.activeProfile {
                        Label("\(p.emoji) \(p.name)", systemImage: "person.fill")
                        Button("Switch to parent mode (no restrictions)") { model.parentMode() }
                    } else {
                        Label("Parent mode, no restrictions", systemImage: "lock.open")
                    }
                }

                Section("Kid profiles") {
                    ForEach(model.profiles) { p in
                        HStack {
                            Text(p.emoji).font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(p.name.isEmpty ? "Unnamed" : p.name).font(.headline)
                                Text(summary(p)).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") { editing = p }
                                .buttonStyle(.bordered)
                            Button("Start") { model.start(p) }
                                .buttonStyle(.borderedProminent)
                                .disabled(!model.authorized)
                        }
                    }
                    Button {
                        editing = KidProfile()
                    } label: {
                        Label("Add a kid profile", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Parent dashboard")
            .toolbar {
                Button("Lock") { model.unlocked = false }
            }
            .sheet(item: $editing) { p in
                ProfileEditor(profile: p)
            }
        }
    }

    private func summary(_ p: KidProfile) -> String {
        let apps = p.allowed.applicationTokens.count
        let limit = p.dailyLimitMinutes > 0
            ? "\(model.usedToday(p))/\(p.dailyLimitMinutes) min today"
            : "no time limit"
        return "\(apps) allowed apps, \(limit)"
    }
}

struct ProfileEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var profile: KidProfile
    @State private var pickingApps = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    TextField("Name", text: $profile.name)
                    TextField("Emoji", text: $profile.emoji)
                }

                Section {
                    Button("Choose allowed apps and websites") { pickingApps = true }
                    Text("\(profile.allowed.applicationTokens.count) apps, \(profile.allowed.webDomainTokens.count) websites allowed")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Apps")
                } footer: {
                    Text("Everything not chosen here is blocked for this child.")
                }

                Section {
                    Stepper(value: $profile.dailyLimitMinutes, in: 0...600, step: 15) {
                        Text(profile.dailyLimitMinutes == 0
                             ? "No daily limit"
                             : "\(profile.dailyLimitMinutes) minutes per day")
                    }
                    Button("Reset today's used time") { model.resetUsage(profile) }
                } header: {
                    Text("Time limit")
                } footer: {
                    Text("Used so far today: \(model.usedToday(profile)) minutes. Usage is recorded in 5-minute steps.")
                }

                Section("Content") {
                    Toggle("Filter adult websites", isOn: $profile.filterAdultWeb)
                    Toggle("Block explicit music, films and books", isOn: $profile.blockExplicitMedia)
                    Toggle("Block app installs and in-app purchases", isOn: $profile.blockInstallsAndPurchases)
                }

                if model.profiles.contains(where: { $0.id == profile.id }) {
                    Section {
                        Button("Delete profile", role: .destructive) {
                            model.delete(profile)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(profile.name.isEmpty ? "New profile" : profile.name)
            .familyActivityPicker(isPresented: $pickingApps, selection: $profile.allowed)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.save(profile)
                        // If this child is using the iPad right now, apply changes immediately.
                        if model.activeID == profile.id { RestrictionEngine.activate(profile) }
                        dismiss()
                    }
                    .disabled(profile.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
