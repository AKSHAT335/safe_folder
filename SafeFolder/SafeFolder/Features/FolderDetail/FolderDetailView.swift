import SwiftUI

/// Screen displaying the files within a specific folder
struct FolderDetailView: View {
    private let initialFolder: Folder
    @EnvironmentObject var folderStore: FolderStore
    
    init(folder: Folder) {
        self.initialFolder = folder
    }
    
    private var folder: Folder {
        folderStore.folder(withId: initialFolder.id) ?? initialFolder
    }
    @AppStorage("isGridView") private var isGridView = false
    @Environment(\.dismiss) private var dismiss
    
    // File Management State
    @State private var showAddFileMenu = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showDocumentPicker = false
    
    // Auto-Lock Timer State
    @State private var inactivityTimer: Timer?
    
    // Error Alert State
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // Delete Confirmation State
    @State private var fileToDelete: FileItem?
    @State private var showDeleteConfirmation = false
    
    // Rename Folder State
    @State private var showRenameAlert = false
    @State private var renameText = ""
    
    // File Preview State
    @State private var fileToPreview: FileItem?
    @State private var showFilePreview = false
    
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
                                    .onTapGesture {
                                        previewFile(file)
                                    }
                                    .contextMenu {
                                        Button {
                                            previewFile(file)
                                        } label: { Label("Preview", systemImage: "eye") }
                                        
                                        Button(role: .destructive) {
                                            fileToDelete = file
                                            showDeleteConfirmation = true
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                } else {
                    List {
                        ForEach(files) { file in
                            Button {
                                previewFile(file)
                            } label: {
                                FileRowView(file: file, folder: folder)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
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
                    
                    Menu {
                        Button {
                            showAddFileMenu = true
                        } label: {
                            Label("Add File", systemImage: "plus")
                        }
                        
                        Button {
                            renameText = folder.name
                            showRenameAlert = true
                        } label: {
                            Label("Rename Folder", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .fontWeight(.semibold)
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
            Button("Camera") { showCamera = true }
            Button("Photo Library") { showPhotoLibrary = true }
            Button("Files") { showDocumentPicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Delete \"\(fileToDelete?.displayName ?? "this file")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let file = fileToDelete {
                    folderStore.deleteFile(file, from: folder.id)
                }
                fileToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                fileToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                saveCapturedImage(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            PhotoPicker { images in
                for image in images {
                    saveCapturedImage(image)
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { urls in
                for url in urls {
                    saveDocument(from: url)
                }
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Rename Folder", isPresented: $showRenameAlert) {
            TextField("Folder Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                renameFolder()
            }
        } message: {
            Text("Enter a new name for this folder.")
        }
        .sheet(item: $fileToPreview) { file in
            let url = StorageService.shared.fileURL(for: file, in: folder)
            FilePreviewView(fileURL: url)
        }
        .onAppear {
            startAutoLockTimer()
        }
        .onDisappear {
            inactivityTimer?.invalidate()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0).onChanged { _ in
                startAutoLockTimer()
            }
        )
    }
    
    // MARK: - File Preview
    
    private func previewFile(_ file: FileItem) {
        guard StorageService.shared.fileExists(file, in: folder) else {
            showError("File not found on disk.")
            return
        }
        fileToPreview = file
        showFilePreview = true
    }
    
    // MARK: - Auto-Lock Timer
    
    private func startAutoLockTimer() {
        inactivityTimer?.invalidate()
        
        // Only run timer if folder is secure
        guard folder.isSecure else { return }
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [folderStore, folder] _ in
            Task { @MainActor in
                folderStore.lockFolder(folder.id)
            }
        }
    }
    
    // MARK: - Rename
    
    private func renameFolder() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showError("Folder name cannot be empty.")
            return
        }
        
        // Check for duplicate names (exclude current folder)
        if folderStore.folders.contains(where: { $0.id != folder.id && $0.name.lowercased() == trimmed.lowercased() }) {
            showError("A folder with this name already exists.")
            return
        }
        
        var updated = folder
        updated.name = trimmed
        updated.modifiedAt = Date()
        folderStore.updateFolder(updated)
    }
    
    // MARK: - File Handling
    
    private func saveCapturedImage(_ image: UIImage) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let name = "Photo-\(formatter.string(from: Date()))-\(Int.random(in: 100...999))"
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            showError("Failed to process the captured image.")
            return
        }
        
        do {
            let fileItem = try StorageService.shared.saveImageData(data, to: folder, withName: name, fileExtension: "jpg")
            folderStore.addFile(fileItem, to: folder.id)
        } catch {
            showError("Failed to save image: \(error.localizedDescription)")
        }
    }
    
    private func saveDocument(from url: URL) {
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        do {
            let fileItem = try StorageService.shared.copyFile(from: url, to: folder, withName: name, fileExtension: ext)
            folderStore.addFile(fileItem, to: folder.id)
        } catch {
            showError("Failed to import file: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
