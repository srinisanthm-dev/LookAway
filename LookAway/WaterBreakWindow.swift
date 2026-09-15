import AppKit
import SwiftUI

final class WaterBreakWindow: NSWindow {
    init(screen: NSScreen, timerManager: TimerManager) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level             = .init(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        isOpaque          = false
        backgroundColor   = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovable         = false
        isReleasedWhenClosed = false        // prevents double-free

        // Let AppKit size the content view — do NOT copy window frame (screen coords)
        contentView = NSHostingView(rootView: WaterBreakOverlayView(timerManager: timerManager))
    }
}
