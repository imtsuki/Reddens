import SwiftUI
import Cocoa

struct InspectorView: View {
    var body: some View {
        List {
            Text("Inspector")
        }
    }
}

class HostedInspectorView: NSView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let inspectorView = NSHostingView(rootView: InspectorView())
        inspectorView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(inspectorView)
        inspectorView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        inspectorView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        inspectorView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        inspectorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}

struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        InspectorView()
    }
}
