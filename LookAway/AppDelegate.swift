import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let timerManager = TimerManager()

    private var statusItem: NSStatusItem!
    private var breakWindows: [BreakWindow] = []
    private var waterBreakWindows: [WaterBreakWindow] = []
    private var mainWindow: NSWindow?
    private var displayTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        buildStatusBar()
        wireTimerCallbacks()
        startDisplayUpdates()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showMainWindow()
        return true
    }

    // MARK: - Status Bar

    private func buildStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Look Away")
        button.image?.isTemplate = true
        button.imagePosition = .imageLeft
        setButtonTitle("20:00", onBreak: false, onWaterBreak: false, paused: false)

        let menu = NSMenu()

        let infoItem = NSMenuItem(title: "Next break in 20:00", action: nil, keyEquivalent: "")
        infoItem.tag = 1
        menu.addItem(infoItem)

        menu.addItem(.separator())

        let showItem = NSMenuItem(title: "Open Look Away", action: #selector(showMainWindow), keyEquivalent: "o")
        menu.addItem(showItem)

        menu.addItem(.separator())

        let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "p")
        pauseItem.tag = 2
        menu.addItem(pauseItem)

        let resetItem = NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r")
        menu.addItem(resetItem)

        let previewItem = NSMenuItem(title: "Preview Break Screen", action: #selector(previewBreak), keyEquivalent: "b")
        menu.addItem(previewItem)

        let previewWaterItem = NSMenuItem(title: "Preview Water Break", action: #selector(previewWaterBreak), keyEquivalent: "w")
        menu.addItem(previewWaterItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Look Away", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func setButtonTitle(_ time: String, onBreak: Bool, onWaterBreak: Bool, paused: Bool) {
        guard let button = statusItem?.button else { return }
        let prefix = onWaterBreak ? " 💧 " : (onBreak ? " 👁 " : (paused ? " ⏸ " : " "))
        let attr = NSAttributedString(
            string: "\(prefix)\(time)",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            ]
        )
        button.attributedTitle = attr
    }

    private func startDisplayUpdates() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshDisplay()
        }
        RunLoop.main.add(t, forMode: .common)
        displayTimer = t
    }

    private func refreshDisplay() {
        guard let menu = statusItem?.menu else { return }

        if timerManager.isOnWaterBreak {
            let s = Int(timerManager.waterBreakTimeRemaining)
            let label = "0:\(String(format: "%02d", s))"
            setButtonTitle(label, onBreak: false, onWaterBreak: true, paused: false)
            menu.item(withTag: 1)?.title = "Water break! (\(s)s left)"
        } else if timerManager.isOnBreak {
            let s = Int(timerManager.breakTimeRemaining)
            let label = "0:\(String(format: "%02d", s))"
            setButtonTitle(label, onBreak: true, onWaterBreak: false, paused: false)
            menu.item(withTag: 1)?.title = "Break — look away! (\(s)s left)"
        } else {
            let t = timerManager.formattedWorkTime
            setButtonTitle(t, onBreak: false, onWaterBreak: false, paused: !timerManager.isRunning)
            menu.item(withTag: 1)?.title = timerManager.isRunning
                ? "Next break in \(t)"
                : "Paused — \(t) remaining"
        }

        menu.item(withTag: 2)?.title = timerManager.isRunning ? "Pause" : "Resume"
    }

    // MARK: - Main Window

    @objc func showMainWindow() {
        if mainWindow == nil {
            let content = MainWindowView().environmentObject(timerManager)
            let controller = NSHostingController(rootView: content)
            let win = NSWindow(contentViewController: controller)
            win.title = "Look Away"
            win.styleMask = [.titled, .closable]
            win.setContentSize(NSSize(width: 340, height: 540))
            win.center()
            win.isReleasedWhenClosed = false

            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: win,
                queue: .main
            ) { [weak self] _ in
                self?.mainWindow = nil
            }

            mainWindow = win
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Break Overlay

    private func wireTimerCallbacks() {
        timerManager.onBreakStart = { [weak self] in
            DispatchQueue.main.async { self?.showBreakOverlay() }
        }
        timerManager.onBreakEnd = { [weak self] in
            DispatchQueue.main.async { self?.dismissBreakOverlay() }
        }
        timerManager.onWaterBreakStart = { [weak self] in
            DispatchQueue.main.async { self?.showWaterBreakOverlay() }
        }
        timerManager.onWaterBreakEnd = { [weak self] in
            DispatchQueue.main.async { self?.dismissWaterBreakOverlay() }
        }
    }

    private func showBreakOverlay() {
        guard breakWindows.isEmpty else { return }
        for screen in NSScreen.screens {
            let win = BreakWindow(screen: screen, timerManager: timerManager)
            win.makeKeyAndOrderFront(nil)
            breakWindows.append(win)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismissBreakOverlay() {
        // Hide immediately so the user sees it gone, but keep windows alive
        // until SwiftUI finishes any pending re-renders (prevents use-after-free).
        let closing = breakWindows
        breakWindows.removeAll()
        closing.forEach { $0.orderOut(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            closing.forEach { $0.close() }
        }
    }

    private func showWaterBreakOverlay() {
        guard waterBreakWindows.isEmpty else { return }
        for screen in NSScreen.screens {
            let win = WaterBreakWindow(screen: screen, timerManager: timerManager)
            win.makeKeyAndOrderFront(nil)
            waterBreakWindows.append(win)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismissWaterBreakOverlay() {
        let closing = waterBreakWindows
        waterBreakWindows.removeAll()
        closing.forEach { $0.orderOut(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            closing.forEach { $0.close() }
        }
    }

    // MARK: - Menu Actions

    @objc private func togglePause() {
        if timerManager.isRunning { timerManager.pause() } else { timerManager.start() }
    }

    @objc private func resetTimer() {
        timerManager.reset()
    }

    @objc private func previewBreak() {
        timerManager.triggerBreak()
    }

    @objc private func previewWaterBreak() {
        timerManager.triggerWaterBreak()
    }
}
