import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager

    private let workOptions: [Double] = [5, 10, 15, 20, 25, 30, 40, 45, 60]
    private let breakOptions: [Double] = [10, 15, 20, 30, 45, 60]
    private let waterIntervalOptions: [Double] = [1, 5, 10, 15, 30, 45, 60, 90, 120]
    private let waterBreakOptions: [Double] = [10, 15, 20, 30, 45]

    var body: some View {
        Form {
            Section("Eye Break") {
                Toggle("Remind me to look away", isOn: $timerManager.eyeBreakEnabled)

                Picker("Work interval", selection: Binding(
                    get: { timerManager.workInterval / 60 },
                    set: { timerManager.workInterval = $0 * 60 }
                )) {
                    ForEach(workOptions, id: \.self) { m in
                        Text("\(Int(m)) minutes").tag(m)
                    }
                }
                .disabled(!timerManager.eyeBreakEnabled)

                Picker("Break duration", selection: $timerManager.breakDuration) {
                    ForEach(breakOptions, id: \.self) { s in
                        Text("\(Int(s)) seconds").tag(s)
                    }
                }
                .disabled(!timerManager.eyeBreakEnabled)
            }

            Section("Water Break") {
                Toggle("Remind me to drink water", isOn: $timerManager.waterEnabled)

                Picker("Water interval", selection: Binding(
                    get: { timerManager.waterInterval / 60 },
                    set: { timerManager.waterInterval = $0 * 60 }
                )) {
                    ForEach(waterIntervalOptions, id: \.self) { m in
                        Text("\(Int(m)) minutes").tag(m)
                    }
                }
                .disabled(!timerManager.waterEnabled)

                Picker("Water break duration", selection: $timerManager.waterBreakDuration) {
                    ForEach(waterBreakOptions, id: \.self) { s in
                        Text("\(Int(s)) seconds").tag(s)
                    }
                }
                .disabled(!timerManager.waterEnabled)
            }

            Section("Notifications") {
                Toggle("Play sound at break start", isOn: $timerManager.soundEnabled)
                Toggle("Haptic feedback (Force Touch trackpad)", isOn: $timerManager.hapticsEnabled)
                Toggle("Show notification banner", isOn: $timerManager.notificationsEnabled)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $timerManager.launchAtLoginEnabled)
            }

            Section("Today") {
                HStack {
                    Label("Eye breaks", systemImage: "eye.fill")
                    Spacer()
                    Text("\(timerManager.eyeBreaksToday)").foregroundColor(.secondary)
                }
                HStack {
                    Label("Water glasses", systemImage: "drop.fill")
                    Spacer()
                    Text("\(timerManager.waterGlassesToday)").foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text("Next break in \(timerManager.formattedWorkTime)")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset Timer") {
                        timerManager.reset()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .padding(.vertical)
    }
}
