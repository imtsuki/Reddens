import SwiftUI
import Cocoa
import Combine
import MetalKit

struct InspectorView: View {
    @ObservedObject var inspectorModel: InspectorModel
    var body: some View {
        List {
            Text("Inspector")
                .font(.headline)
            GroupBox(label: Text("Viewing Options")) {
                Slider(value: $inspectorModel.preferences.modelScaling, in: 0.1...10) {
                    Text("Scaling")
                }
            }

            GroupBox(label: Text("Rendering Options")) {
                Picker("Fill mode", selection: $inspectorModel.preferences.triangleFillMode) {
                    Text("Lines").tag(MTLTriangleFillMode.lines)
                    Text("Fill").tag(MTLTriangleFillMode.fill)
                }

                Picker("Lighting mode", selection: $inspectorModel.preferences.lightingMode) {
                    Text("Normal").tag(InspectorModel.Preferences.LightingMode.normal)
                    Text("Hemispheric").tag(InspectorModel.Preferences.LightingMode.hemispheric)
                }
            }
        }
        .listStyle(.inset)
    }
}

class InspectorModel: ObservableObject {
    struct Preferences {
        // MARK: Viewing Options
        var modelScaling: Float = 5.0

        // MARK: Rendering Options
        enum LightingMode {
            case normal
            case hemispheric
        }

        var triangleFillMode: MTLTriangleFillMode = .fill
        var lightingMode: LightingMode = .hemispheric
    }
    @Published var preferences: Preferences = Preferences()
}

class HostedInspectorView: NSView {
    var inspectorModel = InspectorModel()
    var inspectorModelChangeSink: AnyCancellable?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let inspectorView = NSHostingView(rootView: InspectorView(inspectorModel: inspectorModel))
        inspectorView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(inspectorView)
        inspectorView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        inspectorView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        inspectorView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        inspectorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        inspectorModelChangeSink = inspectorModel.$preferences.sink { newPreferences in
            NotificationCenter.default.post(name: Notification.Name("InspectorPreferencesChanged"), object: nil, userInfo: ["preferences": newPreferences])
        }
    }
}

struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        InspectorView(inspectorModel: InspectorModel())
    }
}
