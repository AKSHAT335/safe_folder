//
//  ContentView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            FolderListView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FolderStore())
}
