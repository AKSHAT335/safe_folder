//
//  CreateFolderView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// Screen for creating a new folder with optional security settings
struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var folderStore: FolderStore
    
    @State private var name = ""
    @State private var isSecure = false
    @State private var authType: AuthenticationType = .password
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Folder Details")) {
                    TextField("Folder Name", text: $name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Security")) {
                    Toggle("Secure Folder", isOn: $isSecure.animation())
                    
                    if isSecure {
                        Picker("Authentication", selection: $authType.animation()) {
                            Text("Custom Password").tag(AuthenticationType.password)
                            if BiometricAuthService.shared.canEvaluatePolicy() {
                                Text("Face ID / Touch ID").tag(AuthenticationType.biometric)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                if isSecure && authType == .password {
                    Section(header: Text("Password Setup")) {
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createFolder() }
                        .fontWeight(.bold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createFolder() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        // Validation
        if trimmedName.isEmpty {
            showError(message: "Folder name cannot be empty.")
            return
        }
        
        if folderStore.folders.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            showError(message: "A folder with this name already exists.")
            return
        }
        
        if isSecure && authType == .password {
            if password.isEmpty {
                showError(message: "Password cannot be empty.")
                return
            }
            if password.count < 4 {
                showError(message: "Password must be at least 4 characters.")
                return
            }
            if password != confirmPassword {
                showError(message: "Passwords do not match.")
                return
            }
        }
        
        let newFolder = Folder(
            name: trimmedName,
            isSecure: isSecure,
            authenticationType: isSecure ? authType : .none
        )
        
        // Save Password to Keychain
        if isSecure && authType == .password {
            do {
                try KeychainService.shared.savePassword(password, forFolderId: newFolder.id)
            } catch {
                showError(message: "Failed to securely save password.")
                return
            }
        }
        
        // Save to Store
        folderStore.addFolder(newFolder)
        dismiss()
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    CreateFolderView()
        .environmentObject(FolderStore())
}
