import Cocoa

class MainWindowController: NSWindowController {
    @IBAction func openFile(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.title = "Choose 3D Model"
        if panel.runModal() == .OK {
            let url = panel.urls[0]
            NotificationCenter.default.post(name: Notification.Name("OpenFile"), object: nil, userInfo: ["url": url])
        }
    }
}
