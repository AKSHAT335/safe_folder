//
//  ConvertFolderView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// Screen for converting a Normal folder to a Secure folder
struct ConvertFolderView: View {
    let folder: Folder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var folderStore: FolderStore
    
    @State private var authType: AuthenticationType = .password
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security Setup")) {
                    Picker("Authentication", selection: $authType.animation()) {
                        Text("Custom Password").tag(AuthenticationType.password)
                        if BiometricAuthService.shared.canEvaluatePolicy() {
                            Text("Face ID / Touch ID").tag(AuthenticationType.biometric)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if authType == .password {
                    Section(header: Text("Password Setup")) {
                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                }
            }
            .navigationTitle("Make Secure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveConversion() }
                        .fontWeight(.bold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage) }
        }
    }
    
    private func saveConversion() {
        if authType == .password {
            if password.isEmpty {
                errorMessage = "Password cannot be empty."
                showError = true
                return
            }
            if password != confirmPassword {
                errorMessage = "Passwords do not match."
                showError = true
                return
            }
            
            do {
                try KeychainService.shared.savePassword(password, forFolderId: folder.id)
            } catch {
                errorMessage = "Failed to save password."
                showError = true
                return
            }
        }
        
        let updatedFolder = folder.withSecurity(type: authType)
        folderStore.updateFolder(updatedFolder)
        dismiss()
    }
}
