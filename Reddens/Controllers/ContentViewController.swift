import Cocoa
import MetalKit

class ContentViewController: NSViewController {
    var renderer: Renderer?
    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        renderer = Renderer(metalView: metalView)
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
            renderer?.loadAsset(url: url)
        }
    }

    @objc func inspectorPreferencesChanged(notification: NSNotification) {
        if let preferences = notification.userInfo?["preferences"] as? InspectorModel.Preferences {
            renderer?.inspectorPreferences = preferences
        }
    }
}
