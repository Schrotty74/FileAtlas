//
//  KeychainStore.swift
//  FileAtlas
//
//  Sichere Ablage von Backup-Passwörtern in der macOS-Keychain.
//  Passwörter werden NIE in UserDefaults/JSON gespeichert.
//

import Foundation
import Security

nonisolated enum KeychainStore {

    private static let service = "app.fileatlas.backup"

    /// Speichert (oder ersetzt) das Passwort für ein Konto (z. B. den Ortspfad).
    static func setPassword(_ password: String, for account: String) {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        // Vorhandenen Eintrag entfernen, dann neu anlegen.
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    /// Liest das Passwort für ein Konto, falls vorhanden.
    static func password(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8)
        else { return nil }
        return password
    }

    static func hasPassword(for account: String) -> Bool {
        password(for: account) != nil
    }

    static func deletePassword(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
