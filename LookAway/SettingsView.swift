import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager

    private let workOptions: [Double] = [5, 10, 15, 20, 25, 30, 40, 45, 60]
    private let breakOptions: [Double] = [10, 15, 20, 30, 45, 60]

    var body: some View {
        Form {
            Section("Timer") {
                Picker("Work interval", selection: Binding(
                    get: { timerManager.workInterval / 60 },
                    set: { timerManager.workInterval = $0 * 60 }
                )) {
                    ForEach(workOptions, id: \.self) { m in
                        Text("\(Int(m)) minutes").tag(m)
                    }
                }

                Picker("Break duration", selection: $timerManager.breakDuration) {
                    ForEach(breakOptions, id: \.self) { s in
                        Text("\(Int(s)) seconds").tag(s)
                    }
                }
            }

            Section("Notifications") {
                Toggle("Play sound at break start and end", isOn: $timerManager.soundEnabled)
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
