import CryptoKit
import Foundation
import Security

enum SecureStoreError: LocalizedError {
    case keychain(OSStatus)
    case invalidEnvelope
    case mediaCorrupt

    var errorDescription: String? {
        switch self {
        case .keychain: "The private storage key is unavailable.".gentleLocalized
        case .invalidEnvelope: "The private journal file could not be opened.".gentleLocalized
        case .mediaCorrupt: "This private recording could not be opened.".gentleLocalized
        }
    }
}

final class VaultKeyStore {
    private let service = "com.krazel.gentlenote.vault"
    private let account = "device-only-key-v1"

    func loadOrCreate() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return SymmetricKey(data: data)
        }
        guard status == errSecItemNotFound else { throw SecureStoreError.keychain(status) }

        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw SecureStoreError.keychain(addStatus) }
        return SymmetricKey(data: data)
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStoreError.keychain(status)
        }
    }
}

final class SecureVaultStore {
    let baseURL: URL
    let mediaURL: URL
    let temporaryURL: URL
    private let snapshotURL: URL
    private let preferencesURL: URL
    private let fileManager: FileManager
    private let keyStore: VaultKeyStore

    init(fileManager: FileManager = .default, keyStore: VaultKeyStore = VaultKeyStore()) throws {
        self.fileManager = fileManager
        self.keyStore = keyStore
        let support = try fileManager.url(for: .applicationSupportDirectory,
                                          in: .userDomainMask,
                                          appropriateFor: nil,
                                          create: true)
        baseURL = support.appendingPathComponent("GentleNote", isDirectory: true)
        mediaURL = baseURL.appendingPathComponent("Media", isDirectory: true)
        temporaryURL = baseURL.appendingPathComponent("Temporary", isDirectory: true)
        snapshotURL = baseURL.appendingPathComponent("journal.gnv")
        preferencesURL = baseURL.appendingPathComponent("preferences.gnp")
        try [baseURL, mediaURL, temporaryURL].forEach { url in
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            try protect(url)
        }
        try clearTemporaryFiles()
    }

    func loadSnapshot() throws -> VaultSnapshot {
        guard fileManager.fileExists(atPath: snapshotURL.path) else { return VaultSnapshot() }
        return try decrypt(VaultSnapshot.self, from: snapshotURL)
    }

    func saveSnapshot(_ snapshot: VaultSnapshot) throws {
        try encrypt(snapshot, to: snapshotURL)
    }

    func loadPreferences() throws -> AppPreferences {
        guard fileManager.fileExists(atPath: preferencesURL.path) else { return AppPreferences() }
        return try decrypt(AppPreferences.self, from: preferencesURL)
    }

    func savePreferences(_ preferences: AppPreferences) throws {
        try encrypt(preferences, to: preferencesURL)
    }

    private func encrypt<T: Encodable>(_ value: T, to url: URL) throws {
        let plain = try JSONEncoder.gentle.encode(value)
        let sealed = try AES.GCM.seal(plain, using: keyStore.loadOrCreate())
        guard let combined = sealed.combined else { throw SecureStoreError.invalidEnvelope }
        let staging = temporaryURL.appendingPathComponent(UUID().uuidString)
        try combined.write(to: staging, options: .atomic)
        try protect(staging)
        if fileManager.fileExists(atPath: url.path) {
            _ = try fileManager.replaceItemAt(url, withItemAt: staging, backupItemName: nil, options: [])
        } else {
            try fileManager.moveItem(at: staging, to: url)
            try protect(url)
        }
    }

    private func decrypt<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        let box = try AES.GCM.SealedBox(combined: data)
        let plain = try AES.GCM.open(box, using: keyStore.loadOrCreate())
        return try JSONDecoder.gentle.decode(type, from: plain)
    }

    func importRecording(from source: URL, extension ext: String) throws -> String {
        let name = UUID().uuidString + "." + ext + ".gnm"
        let destination = mediaURL.appendingPathComponent(name)
        let staging = temporaryURL.appendingPathComponent(UUID().uuidString + ".gnm")
        fileManager.createFile(atPath: staging.path, contents: nil)
        let input = try FileHandle(forReadingFrom: source)
        let output = try FileHandle(forWritingTo: staging)
        let key = try keyStore.loadOrCreate()
        do {
            try output.write(contentsOf: Data("GNM1".utf8))
            while let chunk = try input.read(upToCount: 4 * 1_024 * 1_024), !chunk.isEmpty {
                let sealed = try AES.GCM.seal(chunk, using: key)
                guard let combined = sealed.combined else { throw SecureStoreError.invalidEnvelope }
                try output.write(contentsOf: lengthPrefix(combined.count))
                try output.write(contentsOf: combined)
            }
            try output.write(contentsOf: lengthPrefix(0))
            try input.close(); try output.close()
            try fileManager.moveItem(at: staging, to: destination)
            try protect(destination)
            try? fileManager.removeItem(at: source)
            return name
        } catch {
            try? input.close(); try? output.close(); try? fileManager.removeItem(at: staging)
            throw error
        }
    }

    func readableMediaURL(filename: String, extension ext: String) throws -> URL {
        let encrypted = mediaURL.appendingPathComponent(filename)
        let output = temporaryURL.appendingPathComponent(UUID().uuidString + "." + ext)
        fileManager.createFile(atPath: output.path, contents: nil)
        let input = try FileHandle(forReadingFrom: encrypted)
        let writer = try FileHandle(forWritingTo: output)
        let key = try keyStore.loadOrCreate()
        do {
            guard try input.read(upToCount: 4) == Data("GNM1".utf8) else { throw SecureStoreError.mediaCorrupt }
            while true {
                guard let prefix = try input.read(upToCount: 4), prefix.count == 4 else { throw SecureStoreError.mediaCorrupt }
                let length = Int(prefix.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
                if length == 0 { break }
                guard let combined = try input.read(upToCount: length), combined.count == length else { throw SecureStoreError.mediaCorrupt }
                let box = try AES.GCM.SealedBox(combined: combined)
                try writer.write(contentsOf: AES.GCM.open(box, using: key))
            }
            try input.close(); try writer.close(); try protect(output)
            return output
        } catch {
            try? input.close(); try? writer.close(); try? fileManager.removeItem(at: output)
            throw error
        }
    }

    func removeMedia(filename: String?) throws {
        guard let filename else { return }
        let url = mediaURL.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
    }

    func clearTemporaryFiles() throws {
        guard fileManager.fileExists(atPath: temporaryURL.path) else { return }
        for url in try fileManager.contentsOfDirectory(at: temporaryURL,
                                                        includingPropertiesForKeys: nil) {
            try? fileManager.removeItem(at: url)
        }
    }

    func eraseEverything() throws {
        if fileManager.fileExists(atPath: baseURL.path) { try fileManager.removeItem(at: baseURL) }
        try keyStore.delete()
        try fileManager.createDirectory(at: mediaURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
        try protect(baseURL)
        try protect(mediaURL)
        try protect(temporaryURL)
    }

    func storageBreakdown(for vault: VaultSnapshot) -> StorageBreakdown {
        let journal = Int64((try? JSONEncoder.gentle.encode(vault.journalEntries).count) ?? 0)
        let notes = Int64((try? JSONEncoder.gentle.encode(vault.libraryItems.filter { $0.kind == .note }).count) ?? 0)
            + Int64((try? JSONEncoder.gentle.encode(vault.collections).count) ?? 0)
            + Int64((try? JSONEncoder.gentle.encode(vault.tags).count) ?? 0)
        var videos: Int64 = 0
        var audio: Int64 = 0
        for item in vault.libraryItems where item.kind != .note {
            guard let filename = item.encryptedMediaFilename else { continue }
            let size = fileSize(mediaURL.appendingPathComponent(filename))
            if item.kind == .video { videos += size } else { audio += size }
        }
        let temporary = directorySize(temporaryURL)
        return StorageBreakdown(journal: journal, notes: notes, videos: videos, audio: audio, temporary: temporary)
    }

    private func protect(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = url
        try mutable.setResourceValues(values)
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete],
                                      ofItemAtPath: url.path)
    }

    private func lengthPrefix(_ value: Int) -> Data {
        let number = UInt32(value)
        return Data([UInt8((number >> 24) & 0xff), UInt8((number >> 16) & 0xff),
                     UInt8((number >> 8) & 0xff), UInt8(number & 0xff)])
    }

    private func fileSize(_ url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return enumerator.compactMap { $0 as? URL }.reduce(0) { $0 + fileSize($1) }
    }
}

struct StorageBreakdown {
    let journal: Int64
    let notes: Int64
    let videos: Int64
    let audio: Int64
    let temporary: Int64
    var total: Int64 { journal + notes + videos + audio + temporary }
}

extension JSONEncoder {
    static var gentle: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var gentle: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
