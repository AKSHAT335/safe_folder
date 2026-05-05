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
    
    // File Management State
    @State private var showAddFileMenu = false
    @State private var showCamera = false
    
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
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            folderStore.deleteFile(file, from: folder.id)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
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
                        showAddFileMenu = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .confirmationDialog("Add File", isPresented: $showAddFileMenu) {
            Button("Camera") {
                showCamera = true
            }
            Button("Photo Library") {
                // TODO: Step 25
                print("Open Photo Library")
            }
            Button("Files") {
                // TODO: Step 26
                print("Open Files")
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                saveCapturedImage(image)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - File Handling
    
    private func saveCapturedImage(_ image: UIImage) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let name = "Photo-\(formatter.string(from: Date()))"
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            let fileItem = try StorageService.shared.saveImageData(data, to: folder, withName: name, fileExtension: "jpg")
            folderStore.addFile(fileItem, to: folder.id)
        } catch {
            print("Failed to save image: \(error)")
        }
    }
}
