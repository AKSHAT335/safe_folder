🔐 SafeFolder

A privacy-focused iOS app for organizing and protecting files, photos, and documents inside password or biometric-secured folders. Built entirely in SwiftUI with a clean MVVM architecture and zero external dependencies.

## Features

- **Folder Management**
  - Create unlimited normal and secure folders
  - Rename folders anytime
  - Search folders by name
  - File count display for quick reference

- **Security Options**
  - Protect folders with custom passwords
  - Face ID / Touch ID (biometric) authentication
  - Switch between authentication types on existing folders
  - Convert regular folders to secure folders and vice versa
  - Passwords stored securely in iOS Keychain

- **File Management**
  - Import files from Files app
  - Add photos from Photo Library
  - Capture photos directly from camera
  - File preview using QuickLook
  - View images and videos with thumbnails
  - Delete files with confirmation
  - Display file size and creation date

- **Auto-Lock & Safety**
  - Auto-lock secure folders when app goes to background
  - Prevents unauthorized access on interrupted sessions
  - Swipe actions and context menus for quick operations

- **Navigation**
  - Clean navigation using NavigationStack
  - Returns to root when app goes to background
  - Smooth folder browsing experience


## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 17+ |
| Swift | 5.9 |
| Xcode | 15+ |

**No third-party dependencies** — uses only native Swift and SwiftUI APIs.

## Project Architecture

```
SafeFolder/
├── App/
│   ├── SafeFolderApp.swift          # App entry point, scene phase handling
│   └── ContentView.swift             # NavigationStack wrapper
│
├── Core/
│   ├── Models/
│   │   ├── Folder.swift             # Folder struct with auth types
│   │   └── FileItem.swift           # File metadata + type detection
│   │
│   ├── ViewModels/
│   │   └── FolderStore.swift        # Central state management
│   │
│   ├── Services/
│   │   ├── StorageService.swift     # FileManager operations
│   │   ├── KeychainService.swift    # Secure password storage
│   │   └── BiometricAuthService.swift # Face ID / Touch ID
│   │
│   └── Utilities/
│       └── AppLogger.swift          # Logging across services
│
├── Features/
│   ├── FolderList/
│   │   ├── FolderListView.swift
│   │   └── FolderRowView.swift
│   │
│   ├── FolderCreation/
│   │   ├── CreateFolderView.swift
│   │   └── ConvertFolderView.swift
│   │
│   └── FolderDetail/
│       ├── FolderDetailView.swift
│       ├── FileRowView.swift
│       ├── FileGridItemView.swift
│       └── FileThumbnailView.swift
│
├── Shared/
│   └── Components/
│       ├── DocumentPicker.swift
│       ├── PhotoPicker.swift
│       ├── ImagePicker.swift
│       ├── FilePreviewView.swift
│       └── EmptyStateView.swift
│
└── Resources/
    └── Assets.xcassets
```

## Architecture Overview

### MVVM Pattern

The app follows **Model-View-ViewModel** architecture:

```
View (SwiftUI) ──▶ ViewModel (FolderStore) ──▶ Service Layer ──▶ System APIs
                        ▲
                 @Published updates
```

- **View**: Pure SwiftUI components rendering UI
- **ViewModel** (`FolderStore`): Central @ObservableObject managing folder/file state
- **Services**: Encapsulate StorageService, KeychainService, BiometricAuthService
- **Models**: Plain Swift structs (Folder, FileItem) with Codable for persistence

### Data Flow

1. **User Interaction**: Tap button in View
2. **View calls ViewModel**: `folderStore.deleteFolder(id:)`
3. **ViewModel calls Service**: `storageService.deleteDirectory(for:)`
4. **Service modifies disk**: FileManager operations
5. **ViewModel updates @Published**: `folders` array changes
6. **View re-renders**: SwiftUI observes change automatically

## Core Models

### Folder
```swift
struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isSecure: Bool
    var authenticationType: AuthenticationType
    var createdAt: Date
    var modifiedAt: Date
}
```

Supports three auth types:
- `.none` — regular unsecured folder
- `.password` — custom password protection
- `.biometric` — Face ID / Touch ID

### FileItem
```swift
struct FileItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fileExtension: String
    var fileType: FileType              // .image, .pdf, .document, .video, etc.
    var fileSize: Int64
    var createdAt: Date
}
```

File types are auto-detected from extension (image, PDF, document, video, audio, other).

## Services

### StorageService
Manages all file system operations using FileManager:

- `directoryURL(for:)` — Get folder's disk directory
- `copyFile(from:to:)` — Copy file from Files app into folder
- `saveImageData(_:to:)` — Save photo/camera data
- `deleteFile(_:from:)` — Remove file from folder
- `saveMetadata(folders:folderFiles:)` — Persist metadata to JSON
- `loadMetadata()` — Load metadata from JSON

**Directory Structure** on device:
```
Documents/SafeFolderData/
├── metadata.json              # Folder list + file metadata
└── Folders/
    ├── {UUID-1}/
    │   ├── {file-uuid-1}.jpg
    │   ├── {file-uuid-2}.pdf
    │   └── ...
    ├── {UUID-2}/
    │   └── ...
```

### KeychainService
Secures password storage using iOS Keychain:

- `savePassword(_:forFolderId:)` — Store password encrypted
- `getPassword(forFolderId:)` — Retrieve password
- `deletePassword(forFolderId:)` — Remove password

Passwords are stored as plain text in Keychain (automatically encrypted by iOS).

### BiometricAuthService
Handles Face ID / Touch ID authentication:

- `canEvaluatePolicy()` — Check if device supports biometrics
- `authenticate(reason:)` — Prompt user for biometric authentication

## State Management

### FolderStore (Central ViewModel)

```swift
@MainActor
class FolderStore: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var folderFiles: [UUID: [FileItem]] = [:]
    @Published var currentOpenFolderId: UUID?
}
```

**Key Methods:**
- Folder CRUD: `addFolder()`, `deleteFolder(id:)`, `updateFolder()`
- File operations: `addFile(_:to:)`, `deleteFile(_:from:)`
- Security: `unlockFolder()`, `lockFolder()`, `lockAllSecureFolders()`
- Persistence: `loadData()`, `saveData()`

All mutations trigger `saveData()` to persist changes to disk.

## SwiftUI Concepts Used

- `@State` — Local UI state (search text, sheet visibility)
- `@Binding` — Pass mutable state to child views
- `@EnvironmentObject` — Share FolderStore across entire app
- `@StateObject` — Own FolderStore in SafeFolderApp
- `NavigationStack` + `NavigationPath` — Modern navigation
- `.navigationDestination(for:destination:)` — Route by model
- `.sheet()` + `.alert()` — Modals for create/unlock/delete
- `.searchable()` — Search bar integration
- `.swipeActions()` — Swipe-to-delete/convert
- `.contextMenu()` — Long-press actions
- `LazyVGrid` — Adaptive grid for file thumbnails

## Security Model

### Password Protection
- Passwords stored in **iOS Keychain** (encrypted by OS)
- Not stored in UserDefaults or JSON metadata
- Can be updated or removed anytime

### Biometric Authentication
- Uses `LocalAuthentication` framework
- Delegates to system Face ID / Touch ID
- No biometric data is stored by the app

### Auto-Lock
- Secure folders lock when:
  - App enters `.background` or `.inactive` state
  - User manually locks from folder view
  - Navigation path is cleared
- Prevents unauthorized access on interrupted sessions

### File Privacy
- All files stored locally in app's Documents directory
- No cloud sync or iCloud backup (by design)
- Files deleted from disk immediately (no soft delete)

## Design Decisions

### Why MVVM?
Separates UI rendering (Views) from business logic (FolderStore). Makes code testable and scalable without adding the complexity of larger architectures like TCA.

### Why FileManager + JSON instead of CoreData/SwiftData?
Folder metadata is simple and flat:
- No complex relationships or queries
- JSON is portable and human-debuggable
- Actual files are stored as-is on disk
- Simpler mental model for a beginner-level assignment

### Why Keychain for passwords?
UserDefaults is plaintext and syncs to iCloud. Keychain:
- Automatically encrypted by iOS
- Device-specific (no cloud sync)
- Standard practice for credential storage

### Why NavigationStack?
Modern SwiftUI navigation API (iOS 16+). Provides:
- Programmatic control via NavigationPath
- Predictable behavior on app state changes
- Cleaner code than NavigationView + NavigationLink

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/SafeFolder.git
   cd SafeFolder
   ```

2. **Open in Xcode**
   ```bash
   open SafeFolder/SafeFolder.xcodeproj
   ```

3. **Select target device or simulator**

4. **Run (Cmd + R)**

No external dependencies to install.

## Development Notes

- **@MainActor**: FolderStore runs all state updates on main thread for UI safety
- **Security.framework**: Keychain operations are synchronous, run from main actor
- **FileManager**: All file operations are synchronous in StorageService
- **LocalAuthentication**: `authenticate()` is async/await
- **JSON Codable**: Uses `.iso8601` date encoding strategy for portability

## Future Improvements

- Folder color/icon customization
- File sorting (by name, date, size)
- Folder favorites/pinning
- Batch file operations
- File compression
- Folder sharing via secure link
- iCloud sync option
- Recently deleted / trash folder with restore

## Learnings

Building this project reinforced:

- SwiftUI state management and data flow
- MVVM architecture and separation of concerns
- Local file storage using FileManager
- Keychain for secure credential storage
- Biometric authentication with LocalAuthentication
- NavigationStack and modern SwiftUI navigation
- Codable for JSON serialization
- Error handling in async/await context

## Author

**GitHub**: https://github.com/AKSHAT335  
**LinkedIn**: www.linkedin.com/in/akshatsingh17

---

**Last Updated**: May 2026
