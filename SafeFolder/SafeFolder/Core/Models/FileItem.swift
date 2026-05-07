
import Foundation
import UniformTypeIdentifiers

// MARK: - File Type

/// Categorizes files for display purposes (icon selection, preview behavior)
enum FileType: String, Codable {
    case image = "image"
    case pdf = "pdf"
    case document = "document"
    case video = "video"
    case audio = "audio"
    case other = "other"
    
    /// SF Symbol icon name for this file type
    var iconName: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.text"
        case .document: return "doc"
        case .video: return "video"
        case .audio: return "music.note"
        case .other: return "doc.fill"
        }
    }
    
    /// Human-readable label
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .pdf: return "PDF"
        case .document: return "Document"
        case .video: return "Video"
        case .audio: return "Audio"
        case .other: return "File"
        }
    }
    
    /// Determine file type from a file extension
    static func from(extension ext: String) -> FileType {
        let lowered = ext.lowercased()
        
        // Image extensions
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff", "webp", "svg"]
        if imageExtensions.contains(lowered) { return .image }
        
        // PDF
        if lowered == "pdf" { return .pdf }
        
        // Document extensions
        let docExtensions = ["doc", "docx", "txt", "rtf", "pages", "xls", "xlsx", "ppt", "pptx", "csv", "numbers", "keynote"]
        if docExtensions.contains(lowered) { return .document }
        
        // Video extensions
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv"]
        if videoExtensions.contains(lowered) { return .video }
        
        // Audio extensions
        let audioExtensions = ["mp3", "m4a", "wav", "aac", "flac", "ogg"]
        if audioExtensions.contains(lowered) { return .audio }
        
        return .other
    }
    
    /// Determine file type from a UTType
    static func from(utType: UTType) -> FileType {
        if utType.conforms(to: .image) { return .image }
        if utType.conforms(to: .pdf) { return .pdf }
        if utType.conforms(to: .movie) || utType.conforms(to: .video) { return .video }
        if utType.conforms(to: .audio) { return .audio }
        if utType.conforms(to: .text) || utType.conforms(to: .spreadsheet) || utType.conforms(to: .presentation) {
            return .document
        }
        return .other
    }
}

// MARK: - FileItem Model

/// Represents a single file stored within a folder
struct FileItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fileExtension: String
    var fileType: FileType
    var fileSize: Int64
    var createdAt: Date
    
    /// The stored filename on disk (UUID-based to avoid collisions)
    var storedFileName: String {
        if fileExtension.isEmpty {
            return id.uuidString
        }
        return "\(id.uuidString).\(fileExtension)"
    }
    
    /// Display-friendly file name with extension
    var displayName: String {
        if fileExtension.isEmpty {
            return name
        }
        return "\(name).\(fileExtension)"
    }
    
    /// Human-readable file size string
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Whether this file type supports thumbnail preview
    var supportsThumbnail: Bool {
        return fileType == .image || fileType == .pdf || fileType == .video
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        fileExtension: String,
        fileType: FileType? = nil,
        fileSize: Int64 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fileExtension = fileExtension
        self.fileType = fileType ?? FileType.from(extension: fileExtension)
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
}

// MARK: - FileItem Convenience

extension FileItem {
    /// Create a FileItem from a URL (extracts name, extension, size)
    static func from(url: URL) -> FileItem {
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let size: Int64 = {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attrs[.size] as? Int64 {
                return fileSize
            }
            return 0
        }()
        
        return FileItem(
            name: name,
            fileExtension: ext,
            fileSize: size
        )
    }
}
