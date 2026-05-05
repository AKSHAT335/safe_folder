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
    @State private var selectedFolderToUnlock: Folder?
    @State private var showPasswordAlert = false
    @State private var passwordInput = ""
    @State private var showAuthError = false
    
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
        if !folder.isSecure || folderStore.isFolderUnlocked(folder.id) {
            path.append(folder)
        } else {
            selectedFolderToUnlock = folder
            if folder.authenticationType == .biometric {
                authenticateBiometric(for: folder)
            } else if folder.authenticationType == .password {
                passwordInput = ""
                showPasswordAlert = true
            }
        }
    }
    
    private func verifyPassword() {
        guard let folder = selectedFolderToUnlock else { return }
        
        let savedPassword = KeychainService.shared.getPassword(forFolderId: folder.id)
        if passwordInput == savedPassword {
            folderStore.unlockFolder(folder.id)
            path.append(folder)
        } else {
            showAuthError = true
        }
        passwordInput = ""
    }
    
    private func authenticateBiometric(for folder: Folder) {
        Task {
            let success = await BiometricAuthService.shared.authenticate(reason: "Unlock \(folder.name)")
            await MainActor.run {
                if success {
                    folderStore.unlockFolder(folder.id)
                    path.append(folder)
                } else {
                    showAuthError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FolderListView(path: .constant(NavigationPath()))
            .environmentObject(FolderStore())
    }
}
