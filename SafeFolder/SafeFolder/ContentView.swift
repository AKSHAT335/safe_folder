//
//  ContentView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            FolderListView(path: $path)
                .navigationDestination(for: Folder.self) { folder in
                    FolderDetailView(folder: folder)
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FolderStore())
}
