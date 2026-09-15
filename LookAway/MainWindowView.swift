import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var timerManager: TimerManager

    @State private var workMinutes: Double = 20
    @State private var breakSeconds: Double = 20
    @State private var waterMinutes: Double = 45
    @State private var waterBreakSeconds: Double = 15

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 24) {
                    timerRing
                    statsCard
                    eyeBreakCard
                    waterBreakCard
                    preferencesCard
                    actionButtons
                }
                .padding(24)
            }
        }
        .frame(width: 340)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            workMinutes = timerManager.workInterval / 60
            breakSeconds = timerManager.breakDuration
            waterMinutes = timerManager.waterInterval / 60
            waterBreakSeconds = timerManager.waterBreakDuration
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text("Look Away")
                .font(.headline)
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusBadge: some View {
        let (label, color): (String, Color) = timerManager.isOnBreak
            ? ("Break", .orange)
            : (timerManager.isRunning ? "Active" : "Paused", timerManager.isRunning ? .green : .secondary)

        return Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    // MARK: Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                .frame(width: 170, height: 170)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.workTimeRemaining)
                .animation(.linear(duration: 1), value: timerManager.breakTimeRemaining)

            VStack(spacing: 4) {
                Text(timerManager.isOnBreak ? "BREAK" : (timerManager.isRunning ? "WORKING" : "PAUSED"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .kerning(1.5)

                Text(timerManager.isOnBreak
                     ? "\(Int(timerManager.breakTimeRemaining))s"
                     : timerManager.formattedWorkTime)
                    .font(.system(size: 38, weight: .thin, design: .monospaced))
                    .foregroundColor(.primary)

                if !timerManager.isOnBreak {
                    Text("until break")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    private var ringProgress: CGFloat {
        if timerManager.isOnBreak {
            return timerManager.breakDuration > 0
                ? CGFloat(timerManager.breakProgress) : 0
        }
        let total = timerManager.workInterval
        guard total > 0 else { return 0 }
        return CGFloat(1 - timerManager.workTimeRemaining / total)
    }

    private var ringColor: Color {
        timerManager.isOnBreak ? .orange : .accentColor
    }

    // MARK: Eye Break Card

    private var eyeBreakCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Eye Break", systemImage: "eye.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $timerManager.eyeBreakEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if timerManager.isOnBreak {
                Text("👁 Break in progress — \(Int(timerManager.breakTimeRemaining))s left")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            } else if timerManager.eyeBreakEnabled {
                Text("Next break in \(timerManager.formattedWorkTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Work interval
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Work interval")
                        .font(.callout)
                    Spacer()
                    Text("\(Int(workMinutes)) min")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $workMinutes, in: 1...60, step: 1) { editing in
                    if !editing {
                        timerManager.workInterval = workMinutes * 60
                    }
                }
                .accentColor(.accentColor)
                .disabled(!timerManager.eyeBreakEnabled)
            }

            // Break duration
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Break duration")
                        .font(.callout)
                    Spacer()
                    Text("\(Int(breakSeconds)) sec")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $breakSeconds, in: 5...120, step: 5) { editing in
                    if !editing {
                        timerManager.breakDuration = breakSeconds
                    }
                }
                .accentColor(.orange)
                .disabled(!timerManager.eyeBreakEnabled)
            }

            Button("Preview Break Screen") {
                timerManager.triggerBreak()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(!timerManager.eyeBreakEnabled)
        }
        .padding(16)
        .background(Color(.controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Preferences Card

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Preferences", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            Toggle(isOn: $timerManager.soundEnabled) {
                Label("Sound at break", systemImage: "speaker.wave.2")
                    .font(.callout)
            }

            Toggle(isOn: $timerManager.hapticsEnabled) {
                Label("Haptic feedback", systemImage: "waveform")
                    .font(.callout)
            }

            Toggle(isOn: $timerManager.notificationsEnabled) {
                Label("Notification banner", systemImage: "bell.badge")
                    .font(.callout)
            }

            Divider()

            Toggle(isOn: $timerManager.launchAtLoginEnabled) {
                Label("Launch at login", systemImage: "power")
                    .font(.callout)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statTile(icon: "eye.fill", tint: .accentColor, value: timerManager.eyeBreaksToday, label: "Eye breaks")
            Divider().frame(height: 40)
            statTile(icon: "drop.fill", tint: .cyan, value: timerManager.waterGlassesToday, label: "Water glasses")
        }
        .padding(.vertical, 14)
        .background(Color(.controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statTile(icon: String, tint: Color, value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Label {
                Text("\(value)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(tint)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Water Break Card

    private var waterBreakCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Water Break", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $timerManager.waterEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if timerManager.isOnWaterBreak {
                Text("💧 Water break in progress — \(Int(timerManager.waterBreakTimeRemaining))s left")
                    .font(.caption)
                    .foregroundColor(.cyan)
            } else if timerManager.waterEnabled {
                Text("Next water break in \(timerManager.formattedWaterTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Water interval")
                        .font(.callout)
                    Spacer()
                    Text("\(Int(waterMinutes)) min")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $waterMinutes, in: 1...120, step: 1) { editing in
                    if !editing {
                        timerManager.waterInterval = waterMinutes * 60
                    }
                }
                .accentColor(.cyan)
                .disabled(!timerManager.waterEnabled)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Water break duration")
                        .font(.callout)
                    Spacer()
                    Text("\(Int(waterBreakSeconds)) sec")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $waterBreakSeconds, in: 5...60, step: 5) { editing in
                    if !editing {
                        timerManager.waterBreakDuration = waterBreakSeconds
                    }
                }
                .accentColor(.cyan)
                .disabled(!timerManager.waterEnabled)
            }

            Button("Preview Water Break") {
                timerManager.triggerWaterBreak()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(!timerManager.waterEnabled)
        }
        .padding(16)
        .background(Color(.controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(timerManager.isRunning && !timerManager.isOnBreak ? "Pause" : "Resume") {
                if timerManager.isRunning && !timerManager.isOnBreak {
                    timerManager.pause()
                } else {
                    timerManager.start()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Reset Timer") {
                timerManager.reset()
                workMinutes = timerManager.workInterval / 60
                breakSeconds = timerManager.breakDuration
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}
