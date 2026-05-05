//
//  FolderListView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// Main screen showing all folders
struct FolderListView: View {
    @EnvironmentObject var folderStore: FolderStore
    
    var body: some View {
        Group {
            if folderStore.folders.isEmpty {
                EmptyStateView(
                    title: "No Folders",
                    message: "Tap the + button to create your first folder.",
                    iconName: "folder.badge.plus"
                )
            } else {
                List {
                    ForEach(folderStore.folders) { folder in
                        FolderRowView(folder: folder, fileCount: folderStore.fileCount(for: folder.id))
                            .contextMenu {
                                Button {
                                    // TODO: Implement Open Action in Step 17
                                    print("Open \(folder.name)")
                                } label: {
                                    Label("Open", systemImage: "folder")
                                }
                                
                                Button(role: .destructive) {
                                    folderStore.deleteFolder(id: folder.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Divider()
                                
                                if folder.isSecure {
                                    Button {
                                        // TODO: Implement Security Removal in Step 32
                                        print("Remove Security")
                                    } label: {
                                        Label("Remove Security", systemImage: "lock.open")
                                    }
                                } else {
                                    Button {
                                        // TODO: Implement Make Secure in Step 31
                                        print("Make Secure")
                                    } label: {
                                        Label("Make Secure", systemImage: "lock")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    folderStore.deleteFolder(id: folder.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Safe Folders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // TODO: Connect to Folder Creation UI in Step 11
                    // Temporarily creating a dummy folder for testing List and Delete actions
                    let newFolder = Folder(
                        name: "Folder \(folderStore.folders.count + 1)",
                        isSecure: folderStore.folders.count % 2 != 0, // Alternate secure/normal for testing
                        authenticationType: folderStore.folders.count % 2 != 0 ? .password : .none
                    )
                    folderStore.addFolder(newFolder)
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FolderListView()
            .environmentObject(FolderStore())
    }
}
