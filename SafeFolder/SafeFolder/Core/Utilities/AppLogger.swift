//
//  AppLogger.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import Foundation
import os

/// Centralized structured logging using Apple's os.Logger
/// Replaces scattered print() calls with categorized, filterable log output
struct AppLogger {
    
    // MARK: - Log Categories
    
    /// Logs related to file storage operations
    static let storage = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SafeFolder", category: "Storage")
    
    /// Logs related to authentication (biometric, password)
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SafeFolder", category: "Auth")
    
    /// Logs related to Keychain operations
    static let keychain = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SafeFolder", category: "Keychain")
    
    /// General-purpose app logs
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SafeFolder", category: "General")
}
