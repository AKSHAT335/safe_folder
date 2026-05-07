//
//  FileRowView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// List row representing a single file
struct FileRowView: View {
    let file: FileItem
    let folder: Folder
    
    var body: some View {
        HStack(spacing: 16) {
            FileThumbnailView(file: file, folder: folder, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(file.formattedSize) • \(file.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}