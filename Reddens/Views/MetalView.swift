import Cocoa
import MetalKit

class MetalView: NSView {
    weak var mtkView: MTKView?
    var renderer: Renderer?
    var displayLink: CVDisplayLink?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let mtkView = MTKView()

        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = true
        mtkView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(mtkView)

        mtkView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        mtkView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        mtkView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mtkView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        self.mtkView = mtkView

        renderer = Renderer(mtkView: mtkView)
    }

    override func viewDidMoveToWindow() {
        func displayLinkOutputCallback(
            _ displayLink: CVDisplayLink,
            _ nowPtr: UnsafePointer<CVTimeStamp>,
            _ outputTimePtr: UnsafePointer<CVTimeStamp>,
            _ flagsIn: CVOptionFlags,
            _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            _ displayLinkContext: UnsafeMutableRawPointer?
        ) -> CVReturn {
            unsafeBitCast(displayLinkContext, to: MetalView.self).mtkView?.draw()
            return kCVReturnSuccess
        }

        // TODO: Seems like Apple's documentation is wrong. `viewDidMoveToWindow` won't get called when view gets moved to another screen.
        // https://developer.apple.com/documentation/metal/onscreen_presentation/creating_a_custom_metal_view
        print("MetalView moved to a new screen")

        if let displayID = self.window?.screen?.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID {
            if let displayLink = self.displayLink {
                CVDisplayLinkStop(displayLink)
            }
            CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)
            CVDisplayLinkSetOutputCallback(
                displayLink!,
                displayLinkOutputCallback,
                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            )
            CVDisplayLinkStart(displayLink!)
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
