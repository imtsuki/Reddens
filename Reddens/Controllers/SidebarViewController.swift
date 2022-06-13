import Cocoa
import SwiftUI
import Combine

class SidebarViewController: NSHostingController<SidebarView> {
    var selectionModel = SelectionModel()
    var selectionModelChangeSink: AnyCancellable?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SidebarView(selectionModel: selectionModel))
        selectionModelChangeSink = selectionModel.$selectedItem.sink { newItem in
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
