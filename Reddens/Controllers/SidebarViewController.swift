import Cocoa
import SwiftUI
import Combine

class SidebarViewController: NSHostingController<SidebarView> {
    var sidebarSelectionModel = SidebarSelectionModel()
    var selectionModelChangeSink: AnyCancellable?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SidebarView(selectionModel: sidebarSelectionModel))
        selectionModelChangeSink = sidebarSelectionModel.$selectedItem.sink { newItem in
            print("selected \(newItem)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
