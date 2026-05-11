import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var folderStore: FolderStore
    
    var body: some View {
        NavigationStack(path: $path) {
            FolderListView(path: $path)
                .navigationDestination(for: Folder.self) { folder in
                    FolderDetailView(folder: folder)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Pop all views to return to the root folder list
                path = NavigationPath()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FolderStore())
}
