import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        if !model.hasPIN {
            SetupView()
        } else if model.unlocked {
            ParentDashboard()
        } else {
            LockView()
        }
    }
}

/// First launch: choose the parent PIN and grant Screen Time access.
struct SetupView: View {
    @EnvironmentObject var model: AppModel
    @State private var pin = ""
    @State private var confirm = ""

    private var valid: Bool { pin.count >= 4 && pin == confirm }

    var body: some View {
        NavigationStack {
            Form {
                Section("Create a parent PIN (4+ digits)") {
                    SecureField("PIN", text: $pin).keyboardType(.numberPad)
                    SecureField("Repeat PIN", text: $confirm).keyboardType(.numberPad)
                }
                Section {
                    Button("Continue") {
                        ParentPIN.set(pin)
                        model.hasPIN = true
                        model.unlocked = true
                        Task { await model.requestAuthorization() }
                    }
                    .disabled(!valid)
                } footer: {
                    Text("Next, iPadOS will ask you to allow Screen Time access. This is what lets the app restrict other apps.")
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

/// What the kids see: who is active, time used, and a PIN gate for the parent.
struct LockView: View {
    @EnvironmentObject var model: AppModel
    @State private var pin = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 24) {
            if let p = model.activeProfile {
                Text(p.emoji).font(.system(size: 96))
                Text(p.name).font(.largeTitle.bold())
                if p.dailyLimitMinutes > 0 {
                    let used = min(model.usedToday(p), p.dailyLimitMinutes)
                    ProgressView(value: Double(used), total: Double(p.dailyLimitMinutes))
                        .frame(maxWidth: 320)
                    Text("\(p.dailyLimitMinutes - used) of \(p.dailyLimitMinutes) minutes left today")
                        .foregroundStyle(.secondary)
                } else {
                    Text("No time limit today").foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "lock.open").font(.system(size: 72))
                Text("Parent mode").font(.largeTitle.bold())
                Text("No restrictions are active.").foregroundStyle(.secondary)
            }

            Divider().frame(maxWidth: 320)

            VStack(spacing: 12) {
                SecureField("Parent PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                Button("Unlock") {
                    if ParentPIN.check(pin) {
                        model.unlocked = true
                        wrong = false
                    } else {
                        wrong = true
                    }
                    pin = ""
                }
                .buttonStyle(.borderedProminent)
                if wrong {
                    Text("Wrong PIN").foregroundStyle(.red)
                }
            }
        }
        .padding()
    }
}
