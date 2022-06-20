import SwiftUI
import Cocoa
import Combine
import MetalKit

struct InspectorView: View {
    @ObservedObject var inspectorModel: InspectorModel
    var body: some View {
        List {
            Group {
                Text("Viewing Options")
                    .font(.headline)

                Slider(value: $inspectorModel.preferences.modelScaling, in: -3...1) {
                    Text("Scaling")
                }

                Divider()

                Group {
                    Slider(value: $inspectorModel.preferences.rotationX, in: 0...2 * Float.pi) {
                        Text("X")
                    }

                    Slider(value: $inspectorModel.preferences.rotationY, in: 0...2 * Float.pi) {
                        Text("Y")
                    }

                    Slider(value: $inspectorModel.preferences.rotationZ, in: 0...2 * Float.pi) {
                        Text("Z")
                    }
                }

                Divider()

                Group {
                    Slider(value: $inspectorModel.preferences.translationX, in: -1...1) {
                        Image(systemName: "arrow.left.and.right")
                    }

                    Slider(value: $inspectorModel.preferences.translationY, in: -1...1) {
                        Image(systemName: "arrow.up.and.down")
                    }
                }
            }

            Divider()

            Group {
                Text("Rendering Options")
                    .font(.headline)

                Picker("Fill mode", selection: $inspectorModel.preferences.triangleFillMode) {
                    Text("Lines").tag(MTLTriangleFillMode.lines)
                    Text("Fill").tag(MTLTriangleFillMode.fill)
                }

                Picker("Lighting", selection: $inspectorModel.preferences.lightingMode) {
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
        var modelScaling: Float = 0
        var rotationX: Float = 0
        var rotationY: Float = 0
        var rotationZ: Float = 0
        var translationX: Float = 0
        var translationY: Float = 0

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
