//
//  FolderStore.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import Foundation
import SwiftUI

/// Main view model that manages all folder operations
/// Acts as the single source of truth for folder and file data
@MainActor
class FolderStore: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var folders: [Folder] = []
    @Published var folderFiles: [UUID: [FileItem]] = [:]  // folder ID -> files
    @Published var currentOpenFolderId: UUID? = nil
    
    // MARK: - Services
    
    private let storage = StorageService.shared
    
    // MARK: - Initialization
    
    init() {
        loadData()
    }
    
    // MARK: - Persistence
    
    /// Load all data from disk
    private func loadData() {
        let (loadedFolders, loadedFiles) = storage.loadMetadata()
        self.folders = loadedFolders
        self.folderFiles = loadedFiles
    }
    
    /// Save all data to disk
    private func saveData() {
        storage.saveMetadata(folders: folders, folderFiles: folderFiles)
    }
    
    // MARK: - Folder CRUD
    
    /// Add a new folder and create its directory on disk
    func addFolder(_ folder: Folder) {
        folders.append(folder)
        folderFiles[folder.id] = []
        // Create the directory on disk
        _ = storage.directoryURL(for: folder)
        saveData()
    }
    
    /// Delete a folder, all its files, and its directory
    func deleteFolder(id: UUID) {
        guard let folder = folder(withId: id) else { return }
        
        // Delete directory from disk
        try? storage.deleteDirectory(for: folder)
        
        // Remove from memory
        folders.removeAll { $0.id == id }
        folderFiles.removeValue(forKey: id)
        
        // If this folder was open, close it
        if currentOpenFolderId == id {
            currentOpenFolderId = nil
        }
        
        saveData()
    }
    
    /// Update an existing folder's metadata
    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveData()
        }
    }
    
    /// Get a folder by ID
    func folder(withId id: UUID) -> Folder? {
        return folders.first { $0.id == id }
    }
    
    // MARK: - File Management
    
    /// Get files for a folder
    func files(for folderId: UUID) -> [FileItem] {
        return folderFiles[folderId] ?? []
    }
    
    /// Add a file to a folder
    func addFile(_ file: FileItem, to folderId: UUID) {
        if folderFiles[folderId] != nil {
            folderFiles[folderId]?.append(file)
        } else {
            folderFiles[folderId] = [file]
        }
        saveData()
    }
    
    /// Remove a file from a folder
    func deleteFile(_ file: FileItem, from folderId: UUID) {
        guard let folder = folder(withId: folderId) else { return }
        
        // Delete from disk
        try? storage.deleteFile(file, from: folder)
        
        // Remove from memory
        folderFiles[folderId]?.removeAll { $0.id == file.id }
        saveData()
    }
    
    /// Get the file count for a folder
    func fileCount(for folderId: UUID) -> Int {
        return folderFiles[folderId]?.count ?? 0
    }
    
    // MARK: - Security / Lock State
    
    /// Lock all secure folders — called when app goes to background
    func lockAllSecureFolders() {
        currentOpenFolderId = nil
    }
    
    /// Check if a folder is currently unlocked
    func isFolderUnlocked(_ folderId: UUID) -> Bool {
        return currentOpenFolderId == folderId
    }
    
    /// Mark a folder as unlocked after successful authentication
    func unlockFolder(_ folderId: UUID) {
        currentOpenFolderId = folderId
    }
    
    /// Lock a specific folder
    func lockFolder(_ folderId: UUID) {
        if currentOpenFolderId == folderId {
            currentOpenFolderId = nil
        }
    }
}
