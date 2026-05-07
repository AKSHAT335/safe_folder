//
//  BiometricAuthService.swift
//  SafeFolder
//
//  Created for iOS Internship Assignment
//

import Foundation
import LocalAuthentication

/// Service for handling Face ID / Touch ID authentication
final class BiometricAuthService: @unchecked Sendable {
    
    static let shared = BiometricAuthService()
    private init() {}
    
    /// Check if the device supports and has enrolled biometrics
    func canEvaluatePolicy() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Prompt the user to authenticate using biometrics
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            AppLogger.auth.error("Biometric Auth Failed: \(error.localizedDescription)")
            return false
        }
    }
}
