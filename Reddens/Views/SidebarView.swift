import SwiftUI

struct SidebarView: View {
    @ObservedObject var selectionModel: SelectionModel
    @State private var isFlagged = false
    var body: some View {
        List() {
            Button {
                selectionModel.selectedItem = .home
            } label: {
                Label("Home", systemImage: "house")
            }
            Button {
                selectionModel.selectedItem = .settings
            } label: {
                Label("Settings", systemImage: "gear")
            }

        }
        .listStyle(.sidebar)
        .buttonStyle(.plain)
    }
}

enum SidebarItem: Hashable {
    case home
    case settings
}

class SelectionModel: ObservableObject {
    @Published var selectedItem: SidebarItem = .home
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selectionModel: SelectionModel())
    }
}
