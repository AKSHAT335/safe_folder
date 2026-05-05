//
//  FolderDetailView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// Screen displaying the files within a specific folder
struct FolderDetailView: View {
    let folder: Folder
    @EnvironmentObject var folderStore: FolderStore
    @AppStorage("isGridView") private var isGridView = false
    
    var body: some View {
        Group {
            let files = folderStore.files(for: folder.id)
            if files.isEmpty {
                EmptyStateView(
                    title: "Empty Folder",
                    message: "Tap + to add files to this folder.",
                    iconName: "doc.text.magnifyingglass"
                )
            } else {
                if isGridView {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(files) { file in
                                FileGridItemView(file: file, folder: folder)
                            }
                        }
                        .padding()
                    }
                } else {
                    List {
                        ForEach(files) { file in
                            FileRowView(file: file, folder: folder)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        folderStore.deleteFile(file, from: folder.id)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isGridView.toggle()
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }
                    
                    Button {
                        // TODO: Implement Add File in Phase 6 (Step 23)
                        print("Add file")
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}
