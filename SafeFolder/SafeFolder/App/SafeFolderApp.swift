import SwiftUI

@main
struct SafeFolderApp: App {
    @StateObject private var folderStore = FolderStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(folderStore)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        // Lock all secure folders when app goes to background
                        folderStore.lockAllSecureFolders()
                    }
                }
        }
    }
}
