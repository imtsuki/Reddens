import Cocoa
import MetalKit

class ContentViewController: NSViewController {
    @IBOutlet weak var metalView: MetalView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(openFile), name: Notification.Name("OpenFile"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(inspectorPreferencesChanged), name: Notification.Name("InspectorPreferencesChanged"), object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func openFile(notification: NSNotification) {
        if let url = notification.userInfo?["url"] as? URL {
            print(url)
            metalView.renderer?.loadAsset(url: url)
        }
    }

    @objc func inspectorPreferencesChanged(notification: NSNotification) {
        if let preferences = notification.userInfo?["preferences"] as? InspectorModel.Preferences {
            metalView.renderer?.inspectorPreferences = preferences
        }
    }
}
