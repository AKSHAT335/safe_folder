//
//  FolderListView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// Main screen showing all folders
struct FolderListView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var folderStore: FolderStore
    
    @State private var showingCreateFolder = false
    
    // Auth State
    enum AuthAction {
        case open
        case removeSecurity
    }
    
    @State private var selectedFolderToUnlock: Folder?
    @State private var showPasswordAlert = false
    @State private var passwordInput = ""
    @State private var showAuthError = false
    @State private var pendingAuthAction: AuthAction = .open
    
    // Conversion State
    @State private var folderToConvert: Folder?
    @State private var showConvertSheet = false
    
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
                        Button {
                            openFolder(folder)
                        } label: {
                            FolderRowView(folder: folder, fileCount: folderStore.fileCount(for: folder.id))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                openFolder(folder)
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
                                    initiateRemoveSecurity(folder)
                                } label: {
                                    Label("Remove Security", systemImage: "lock.open")
                                }
                            } else {
                                Button {
                                    folderToConvert = folder
                                    showConvertSheet = true
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
                    showingCreateFolder = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingCreateFolder) {
            CreateFolderView()
        }
        .sheet(item: $folderToConvert) { folder in
            ConvertFolderView(folder: folder)
        }
        .alert("Enter Password", isPresented: $showPasswordAlert) {
            SecureField("Password", text: $passwordInput)
            Button("Cancel", role: .cancel) { passwordInput = "" }
            Button("Unlock") {
                verifyPassword()
            }
        } message: {
            Text("This folder is protected by a custom password.")
        }
        .alert("Authentication Failed", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Navigation & Authentication
    
    private func openFolder(_ folder: Folder) {
        pendingAuthAction = .open
        if !folder.isSecure || folderStore.isFolderUnlocked(folder.id) {
            path.append(folder)
        } else {
            promptAuth(for: folder)
        }
    }
    
    private func initiateRemoveSecurity(_ folder: Folder) {
        pendingAuthAction = .removeSecurity
        promptAuth(for: folder)
    }
    
    private func promptAuth(for folder: Folder) {
        selectedFolderToUnlock = folder
        if folder.authenticationType == .biometric {
            authenticateBiometric(for: folder)
        } else if folder.authenticationType == .password {
            passwordInput = ""
            showPasswordAlert = true
        }
    }
    
    private func verifyPassword() {
        guard let folder = selectedFolderToUnlock else { return }
        
        let savedPassword = KeychainService.shared.getPassword(forFolderId: folder.id)
        if passwordInput == savedPassword {
            handleSuccessfulAuth(for: folder)
        } else {
            showAuthError = true
        }
        passwordInput = ""
    }
    
    private func authenticateBiometric(for folder: Folder) {
        Task {
            let success = await BiometricAuthService.shared.authenticate(reason: "Authenticate for \(folder.name)")
            await MainActor.run {
                if success {
                    handleSuccessfulAuth(for: folder)
                } else {
                    showAuthError = true
                }
            }
        }
    }
    
    private func handleSuccessfulAuth(for folder: Folder) {
        folderStore.unlockFolder(folder.id)
        
        if pendingAuthAction == .open {
            path.append(folder)
        } else if pendingAuthAction == .removeSecurity {
            removeSecurity(from: folder)
        }
    }
    
    private func removeSecurity(from folder: Folder) {
        if folder.authenticationType == .password {
            try? KeychainService.shared.deletePassword(forFolderId: folder.id)
        }
        let updatedFolder = folder.withoutSecurity()
        folderStore.updateFolder(updatedFolder)
    }
}

#Preview {
    NavigationStack {
        FolderListView(path: .constant(NavigationPath()))
            .environmentObject(FolderStore())
    }
}
