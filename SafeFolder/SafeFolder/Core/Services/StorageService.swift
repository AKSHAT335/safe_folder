import Foundation
import os

/// Manages local file storage using FileManager
/// Handles directory creation, file copying, and metadata persistence
final class StorageService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = StorageService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    
    /// Root directory for all app data within Documents
    private var appRootDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("SafeFolderData", isDirectory: true)
    }
    
    /// Directory containing all folder subdirectories
    private var foldersDirectory: URL {
        return appRootDirectory.appendingPathComponent("Folders", isDirectory: true)
    }
    
    /// Path to the metadata JSON file
    private var metadataFileURL: URL {
        return appRootDirectory.appendingPathComponent("metadata.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        createDirectoryIfNeeded(at: appRootDirectory)
        createDirectoryIfNeeded(at: foldersDirectory)
    }
    
    // MARK: - Directory Management
    
    /// Create a directory if it doesn't already exist
    private func createDirectoryIfNeeded(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Get the directory URL for a specific folder
    func directoryURL(for folder: Folder) -> URL {
        let url = foldersDirectory.appendingPathComponent(folder.directoryName, isDirectory: true)
        createDirectoryIfNeeded(at: url)
        return url
    }
    
    /// Delete the directory for a specific folder (including all files)
    func deleteDirectory(for folder: Folder) throws {
        let url = foldersDirectory.appendingPathComponent(folder.directoryName, isDirectory: true)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - File Operations
    
    /// Copy a file into a folder's directory, returning the stored file item
    func copyFile(from sourceURL: URL, to folder: Folder, withName name: String, fileExtension: String) throws -> FileItem {
        let fileItem = FileItem(name: name, fileExtension: fileExtension)
        let folderDir = directoryURL(for: folder)
        let destinationURL = folderDir.appendingPathComponent(fileItem.storedFileName)
        
        // Access security-scoped resource if needed
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // Get actual file size after copy
        let attrs = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        
        return FileItem(
            id: fileItem.id,
            name: name,
            fileExtension: fileExtension,
            fileType: fileItem.fileType,
            fileSize: size,
            createdAt: fileItem.createdAt
        )
    }
    
    /// Save image data into a folder's directory
    func saveImageData(_ data: Data, to folder: Folder, withName name: String, fileExtension: String = "jpg") throws -> FileItem {
        let fileItem = FileItem(name: name, fileExtension: fileExtension)
        let folderDir = directoryURL(for: folder)
        let destinationURL = folderDir.appendingPathComponent(fileItem.storedFileName)
        
        try data.write(to: destinationURL)
        
        return FileItem(
            id: fileItem.id,
            name: name,
            fileExtension: fileExtension,
            fileType: .image,
            fileSize: Int64(data.count),
            createdAt: fileItem.createdAt
        )
    }
    
    /// Get the full URL for a stored file
    func fileURL(for fileItem: FileItem, in folder: Folder) -> URL {
        let folderDir = directoryURL(for: folder)
        return folderDir.appendingPathComponent(fileItem.storedFileName)
    }
    
    /// Delete a specific file from a folder
    func deleteFile(_ fileItem: FileItem, from folder: Folder) throws {
        let url = fileURL(for: fileItem, in: folder)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    /// Check if a file exists on disk
    func fileExists(_ fileItem: FileItem, in folder: Folder) -> Bool {
        let url = fileURL(for: fileItem, in: folder)
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - Metadata Persistence (JSON + Codable)
    
    /// Data structure persisted to disk
    private struct AppData: Codable {
        var folders: [Folder]
        var folderFiles: [String: [FileItem]]  // folder ID -> files
    }
    
    /// Save all folders and their file metadata to JSON
    func saveMetadata(folders: [Folder], folderFiles: [UUID: [FileItem]]) {
        // Convert UUID keys to String for Codable
        var stringKeyedFiles: [String: [FileItem]] = [:]
        for (key, value) in folderFiles {
            stringKeyedFiles[key.uuidString] = value
        }
        
        let appData = AppData(folders: folders, folderFiles: stringKeyedFiles)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(appData)
            try data.write(to: metadataFileURL, options: .atomicWrite)
        } catch {
            AppLogger.storage.error("Failed to save metadata: \(error.localizedDescription)")
        }
    }
    
    /// Load all folders and their file metadata from JSON
    func loadMetadata() -> (folders: [Folder], folderFiles: [UUID: [FileItem]]) {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return ([], [:])
        }
        
        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let appData = try decoder.decode(AppData.self, from: data)
            
            // Convert String keys back to UUID
            var uuidKeyedFiles: [UUID: [FileItem]] = [:]
            for (key, value) in appData.folderFiles {
                if let uuid = UUID(uuidString: key) {
                    uuidKeyedFiles[uuid] = value
                }
            }
            
            return (appData.folders, uuidKeyedFiles)
        } catch {
            AppLogger.storage.error("Failed to load metadata: \(error.localizedDescription)")
            return ([], [:])
        }
    }
}
