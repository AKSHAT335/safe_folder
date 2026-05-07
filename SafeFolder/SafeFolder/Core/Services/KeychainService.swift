import Foundation
import Security

/// Service for securely storing passwords in the iOS Keychain
final class KeychainService: @unchecked Sendable {
    
    static let shared = KeychainService()
    private init() {}
    
    /// Save a password for a specific folder ID
    func savePassword(_ password: String, forFolderId folderId: UUID) throws {
        let key = folderId.uuidString
        guard let data = password.data(using: .utf8) else { return }
        
        // Remove existing if needed
        try? deletePassword(forFolderId: folderId)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save to Keychain"])
        }
    }
    
    /// Retrieve a password for a specific folder ID
    func getPassword(forFolderId folderId: UUID) -> String? {
        let key = folderId.uuidString
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete a password for a specific folder ID
    func deletePassword(forFolderId folderId: UUID) throws {
        let key = folderId.uuidString
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to delete from Keychain"])
        }
    }
}
