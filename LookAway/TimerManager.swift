import Foundation
import AppKit

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isOnBreak = false
    @Published var workTimeRemaining: TimeInterval = 0
    @Published var breakTimeRemaining: TimeInterval = 0

    @Published var workInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(workInterval, forKey: "workInterval")
            reset()
        }
    }

    @Published var breakDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(breakDuration, forKey: "breakDuration")
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    var onBreakStart: (() -> Void)?
    var onBreakEnd: (() -> Void)?

    private var timer: Timer?

    init() {
        let savedWork = UserDefaults.standard.double(forKey: "workInterval")
        let savedBreak = UserDefaults.standard.double(forKey: "breakDuration")
        let savedSound = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true

        workInterval = savedWork > 0 ? savedWork : 20 * 60
        breakDuration = savedBreak > 0 ? savedBreak : 20
        soundEnabled = savedSound
        workTimeRemaining = workInterval
        breakTimeRemaining = breakDuration

        start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        isOnBreak = false
        workTimeRemaining = workInterval
        breakTimeRemaining = breakDuration
        start()
    }

    func skip() {
        guard isOnBreak else { return }
        endBreak()
    }

    func snooze(minutes: Double = 5) {
        guard isOnBreak else { return }
        endBreak()
        workTimeRemaining = minutes * 60
    }

    var formattedWorkTime: String {
        let m = Int(workTimeRemaining) / 60
        let s = Int(workTimeRemaining) % 60
        return String(format: "%d:%02d", m, s)
    }

    var breakProgress: Double {
        guard breakDuration > 0 else { return 0 }
        return 1.0 - (breakTimeRemaining / breakDuration)
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        if isOnBreak {
            if breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
            } else {
                endBreak()
            }
        } else {
            if workTimeRemaining > 0 {
                workTimeRemaining -= 1
            } else {
                beginBreak()
            }
        }
    }

    func triggerBreak() {
        guard !isOnBreak else { return }
        beginBreak()
    }

    private func beginBreak() {
        isOnBreak = true
        breakTimeRemaining = breakDuration
        playSound(named: "Glass")
        onBreakStart?()
    }

    private func endBreak() {
        isOnBreak = false
        workTimeRemaining = workInterval
        playSound(named: "Ping")
        onBreakEnd?()
    }

    /// Plays a named macOS system sound when sound is enabled,
    /// falling back to the system beep if the sound can't be loaded.
    private func playSound(named name: String) {
        guard soundEnabled else { return }
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.stop()
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
