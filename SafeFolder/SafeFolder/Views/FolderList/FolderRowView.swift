//
//  FolderRowView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// A row component representing a single folder in the list
struct FolderRowView: View {
    let folder: Folder
    let fileCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: folder.iconName)
                .font(.system(size: 32))
                .foregroundColor(folder.isSecure ? .red : .accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                
                Text("\(fileCount) file\(fileCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if folder.isSecure {
                Image(systemName: folder.authenticationType.iconName)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        FolderRowView(folder: Folder(name: "Normal Folder", isSecure: false), fileCount: 5)
        FolderRowView(folder: Folder(name: "Secure Folder", isSecure: true, authenticationType: .password), fileCount: 0)
    }
}
