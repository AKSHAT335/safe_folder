//
//  EmptyStateView.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import SwiftUI

/// A reusable component for displaying an empty state
struct EmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "No Folders",
        message: "Tap the + button to create your first folder.",
        iconName: "folder.badge.plus"
    )
}
