import Foundation
import AppKit
import UserNotifications
import ServiceManagement

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isOnBreak = false
    @Published var workTimeRemaining: TimeInterval = 0
    @Published var breakTimeRemaining: TimeInterval = 0

    @Published var isOnWaterBreak = false
    @Published var waterTimeRemaining: TimeInterval = 0
    @Published var waterBreakTimeRemaining: TimeInterval = 0

    @Published var eyeBreaksToday: Int {
        didSet { UserDefaults.standard.set(eyeBreaksToday, forKey: "eyeBreaksToday") }
    }
    @Published var waterGlassesToday: Int {
        didSet { UserDefaults.standard.set(waterGlassesToday, forKey: "waterGlassesToday") }
    }

    @Published var eyeBreakEnabled: Bool {
        didSet {
            UserDefaults.standard.set(eyeBreakEnabled, forKey: "eyeBreakEnabled")
        }
    }

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

    @Published var waterEnabled: Bool {
        didSet {
            UserDefaults.standard.set(waterEnabled, forKey: "waterEnabled")
        }
    }

    @Published var waterInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(waterInterval, forKey: "waterInterval")
            waterTimeRemaining = waterInterval
        }
    }

    @Published var waterBreakDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(waterBreakDuration, forKey: "waterBreakDuration")
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet {
            guard launchAtLoginEnabled != oldValue else { return }
            do {
                if launchAtLoginEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
                }
            }
        }
    }

    var onBreakStart: (() -> Void)?
    var onBreakEnd: (() -> Void)?
    var onWaterBreakStart: (() -> Void)?
    var onWaterBreakEnd: (() -> Void)?

    private var timer: Timer?
    private var statsDay: Double

    init() {
        let savedEyeBreakEnabled = UserDefaults.standard.object(forKey: "eyeBreakEnabled") as? Bool ?? true
        let savedWork = UserDefaults.standard.double(forKey: "workInterval")
        let savedBreak = UserDefaults.standard.double(forKey: "breakDuration")
        let savedSound = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        let savedHaptics = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        let savedNotifications = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        let savedWaterEnabled = UserDefaults.standard.object(forKey: "waterEnabled") as? Bool ?? true
        let savedWaterInterval = UserDefaults.standard.double(forKey: "waterInterval")
        let savedWaterBreak = UserDefaults.standard.double(forKey: "waterBreakDuration")
        let savedStatsDay = UserDefaults.standard.double(forKey: "statsDay")
        let savedEyeBreaks = UserDefaults.standard.integer(forKey: "eyeBreaksToday")
        let savedWaterGlasses = UserDefaults.standard.integer(forKey: "waterGlassesToday")

        eyeBreakEnabled = savedEyeBreakEnabled
        workInterval = savedWork > 0 ? savedWork : 20 * 60
        breakDuration = savedBreak > 0 ? savedBreak : 20
        soundEnabled = savedSound
        hapticsEnabled = savedHaptics
        notificationsEnabled = savedNotifications
        waterEnabled = savedWaterEnabled
        waterInterval = savedWaterInterval > 0 ? savedWaterInterval : 45 * 60
        waterBreakDuration = savedWaterBreak > 0 ? savedWaterBreak : 15
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled

        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        if savedStatsDay == today {
            eyeBreaksToday = savedEyeBreaks
            waterGlassesToday = savedWaterGlasses
        } else {
            eyeBreaksToday = 0
            waterGlassesToday = 0
        }
        statsDay = today
        UserDefaults.standard.set(today, forKey: "statsDay")

        workTimeRemaining = workInterval
        breakTimeRemaining = breakDuration
        waterTimeRemaining = waterInterval
        waterBreakTimeRemaining = waterBreakDuration

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

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
        isOnWaterBreak = false
        workTimeRemaining = workInterval
        breakTimeRemaining = breakDuration
        waterTimeRemaining = waterInterval
        waterBreakTimeRemaining = waterBreakDuration
        start()
    }

    func skip() {
        guard isOnBreak else { return }
        endBreak(completed: true)
    }

    func snooze(minutes: Double = 5) {
        guard isOnBreak else { return }
        endBreak(completed: false)
        workTimeRemaining = minutes * 60
    }

    func skipWaterBreak() {
        guard isOnWaterBreak else { return }
        endWaterBreak(completed: true)
    }

    func snoozeWaterBreak(minutes: Double = 5) {
        guard isOnWaterBreak else { return }
        endWaterBreak(completed: false)
        waterTimeRemaining = minutes * 60
    }

    var formattedWorkTime: String {
        let m = Int(workTimeRemaining) / 60
        let s = Int(workTimeRemaining) % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedWaterTime: String {
        let m = Int(waterTimeRemaining) / 60
        let s = Int(waterTimeRemaining) % 60
        return String(format: "%d:%02d", m, s)
    }

    var breakProgress: Double {
        guard breakDuration > 0 else { return 0 }
        return 1.0 - (breakTimeRemaining / breakDuration)
    }

    var waterBreakProgress: Double {
        guard waterBreakDuration > 0 else { return 0 }
        return 1.0 - (waterBreakTimeRemaining / waterBreakDuration)
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
        rolloverStatsIfNeeded()

        // Eye break countdown pauses while a water break is showing, and vice versa,
        // so the two full-screen overlays never fight for the screen at once.
        if isOnBreak {
            if breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
            } else {
                endBreak(completed: true)
            }
        } else if eyeBreakEnabled && !isOnWaterBreak {
            if workTimeRemaining > 0 {
                workTimeRemaining -= 1
            } else {
                beginBreak()
            }
        }

        if isOnWaterBreak {
            if waterBreakTimeRemaining > 0 {
                waterBreakTimeRemaining -= 1
            } else {
                endWaterBreak(completed: true)
            }
        } else if waterEnabled && !isOnBreak {
            if waterTimeRemaining > 0 {
                waterTimeRemaining -= 1
            } else {
                beginWaterBreak()
            }
        }
    }

    private func rolloverStatsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        guard today != statsDay else { return }
        statsDay = today
        eyeBreaksToday = 0
        waterGlassesToday = 0
        UserDefaults.standard.set(today, forKey: "statsDay")
    }

    func triggerBreak() {
        guard !isOnBreak else { return }
        beginBreak()
    }

    func triggerWaterBreak() {
        guard !isOnWaterBreak else { return }
        beginWaterBreak()
    }

    /// Distinct system sound per break type, so eye and water reminders are told apart by ear.
    private func notify(title: String, body: String, soundName: NSSound.Name) {
        if soundEnabled {
            (NSSound(named: soundName) ?? NSSound(named: "Tink"))?.play()
        }
        if hapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        }
        if notificationsEnabled {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func beginBreak() {
        isOnBreak = true
        breakTimeRemaining = breakDuration
        notify(title: "Time to Look Away", body: "Focus on something 20 feet away for \(Int(breakDuration))s", soundName: "Ping")
        onBreakStart?()
    }

    private func endBreak(completed: Bool) {
        isOnBreak = false
        workTimeRemaining = workInterval
        if completed { eyeBreaksToday += 1 }
        onBreakEnd?()
    }

    private func beginWaterBreak() {
        isOnWaterBreak = true
        waterBreakTimeRemaining = waterBreakDuration
        notify(title: "Water Break", body: "Time to hydrate! 💧", soundName: "Glass")
        onWaterBreakStart?()
    }

    private func endWaterBreak(completed: Bool) {
        isOnWaterBreak = false
        waterTimeRemaining = waterInterval
        if completed { waterGlassesToday += 1 }
        onWaterBreakEnd?()
    }
}
