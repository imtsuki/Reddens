import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    var priorWindowFrame: NSRect?

    func customWindowsToEnterFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    func customWindowsToExitFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    func window(_ window: NSWindow, startCustomAnimationToEnterFullScreenOn screen: NSScreen, withDuration duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            window.animator().setFrame(screen.frame, display: true, animate: true)
        }, completionHandler: nil)
    }

    func window(_ window: NSWindow, startCustomAnimationToExitFullScreenWithDuration duration: TimeInterval) {
        if NSMenu.menuBarVisible() {
            NSMenu.setMenuBarVisible(false)
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            window.animator().setFrame(priorWindowFrame!, display: true, animate: true)
        }, completionHandler: nil)

        NSMenu.setMenuBarVisible(true)
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        priorWindowFrame = self.window?.frame
    }

    @IBAction func openFile(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.title = "Choose 3D Model"
        if panel.runModal() == .OK {
            let url = panel.urls[0]
            NotificationCenter.default.post(name: Notification.Name("OpenFile"), object: nil, userInfo: ["url": url])
        }
    }
}
