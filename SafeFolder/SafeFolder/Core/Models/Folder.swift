//
//  Folder.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import Foundation

// MARK: - Authentication Type

/// Defines how a secure folder is protected
enum AuthenticationType: String, Codable, CaseIterable {
    case none = "none"
    case password = "password"
    case biometric = "biometric"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .password: return "Custom Password"
        case .biometric: return "Biometric (Face ID / Touch ID)"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "folder"
        case .password: return "lock"
        case .biometric: return "faceid"
        }
    }
}

// MARK: - Folder Model

/// Represents a folder that can hold files, optionally secured with authentication
struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isSecure: Bool
    var authenticationType: AuthenticationType
    var createdAt: Date
    var modifiedAt: Date
    
    /// Unique directory name on disk (uses UUID to avoid conflicts)
    var directoryName: String {
        return id.uuidString
    }
    
    /// System icon name based on folder security status
    var iconName: String {
        if isSecure {
            return "folder.fill.badge.person.crop"
        } else {
            return "folder.fill"
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        isSecure: Bool = false,
        authenticationType: AuthenticationType = .none,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isSecure = isSecure
        self.authenticationType = authenticationType
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Folder Convenience

extension Folder {
    /// Returns true if folder requires password authentication
    var requiresPassword: Bool {
        return isSecure && authenticationType == .password
    }
    
    /// Returns true if folder requires biometric authentication
    var requiresBiometric: Bool {
        return isSecure && authenticationType == .biometric
    }
    
    /// Create a copy with security enabled
    func withSecurity(type: AuthenticationType) -> Folder {
        var copy = self
        copy.isSecure = true
        copy.authenticationType = type
        copy.modifiedAt = Date()
        return copy
    }
    
    /// Create a copy with security removed
    func withoutSecurity() -> Folder {
        var copy = self
        copy.isSecure = false
        copy.authenticationType = .none
        copy.modifiedAt = Date()
        return copy
    }
}
