import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var vault = VaultSnapshot()
    @Published var preferences = AppPreferences()
    @Published var isUnlocked = false
    @Published private(set) var isAuthenticating = false
    @Published var privacyCoverVisible = false
    @Published var lastError: String?
    @Published var selectedTab: RootTab = .journal

    let store: SecureVaultStore
    let authenticator = AuthenticationService()
    private var backgroundedAt: Date?

    init() {
        do {
            store = try SecureVaultStore()
            preferences = try store.loadPreferences()
            vault = try store.loadSnapshot()
            isUnlocked = !preferences.appLockEnabled
        } catch {
            fatalError("Gentle Note could not initialize private storage: \(error.localizedDescription)")
        }
    }

    func savePreferences() {
        do { try store.savePreferences(preferences) }
        catch { lastError = error.localizedDescription }
    }

    func setOnboardingComplete() {
        preferences.onboardingComplete = true
        savePreferences()
    }

    func unlock(reason: String = "Unlock your private journal and library.".gentleLocalized) async -> Bool {
        if !preferences.appLockEnabled {
            isUnlocked = true
            return true
        }
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let ok = await authenticator.authenticate(reason: reason)
        isUnlocked = ok
        return ok
    }

    func authenticateSensitiveAction(reason: String) async -> Bool {
        await authenticator.authenticate(reason: reason)
    }

    func enteredInactive() {
        privacyCoverVisible = true
        try? store.clearTemporaryFiles()
    }

    func enteredBackground() {
        privacyCoverVisible = true
        if backgroundedAt == nil { backgroundedAt = Date() }
        try? store.clearTemporaryFiles()
        if preferences.lockDelay == .immediately { isUnlocked = false }
    }

    func becameActive() {
        privacyCoverVisible = false
        if let backgroundedAt,
           Date().timeIntervalSince(backgroundedAt) >= preferences.lockDelay.seconds {
            isUnlocked = !preferences.appLockEnabled
        }
        self.backgroundedAt = nil
    }

    func saveJournalEntry(_ entry: JournalEntry) throws {
        var changed = vault
        if let index = changed.journalEntries.firstIndex(where: { $0.id == entry.id }) {
            changed.journalEntries[index] = entry
        } else {
            changed.journalEntries.append(entry)
        }
        changed.journalDraft = nil
        try commit(changed)
    }

    func saveJournalDraft(_ draft: JournalDraft?) {
        var changed = vault
        changed.journalDraft = draft
        try? commit(changed)
    }

    func deleteJournalEntry(_ id: UUID) throws {
        var changed = vault
        changed.journalEntries.removeAll { $0.id == id }
        try commit(changed)
    }

    func saveLibraryItem(_ item: LibraryItem) throws {
        var changed = vault
        if let index = changed.libraryItems.firstIndex(where: { $0.id == item.id }) {
            changed.libraryItems[index] = item
        } else {
            changed.libraryItems.append(item)
        }
        changed.libraryDraft = nil
        try commit(changed)
    }

    func saveLibraryDraft(_ draft: LibraryDraft?) {
        var changed = vault
        changed.libraryDraft = draft
        try? commit(changed)
    }

    func deleteLibraryItem(_ id: UUID) throws {
        var changed = vault
        guard let item = changed.libraryItems.first(where: { $0.id == id }) else { return }
        try store.removeMedia(filename: item.encryptedMediaFilename)
        changed.libraryItems.removeAll { $0.id == id }
        try commit(changed)
    }

    func addCollection(_ collection: LibraryCollection) throws {
        var changed = vault
        if let index = changed.collections.firstIndex(where: { $0.id == collection.id }) {
            changed.collections[index] = collection
        } else { changed.collections.append(collection) }
        try commit(changed)
    }

    func deleteCollection(_ id: UUID) throws {
        var changed = vault
        changed.collections.removeAll { $0.id == id }
        for index in changed.libraryItems.indices { changed.libraryItems[index].collectionIDs.remove(id) }
        try commit(changed)
    }

    func addTag(named name: String) throws -> LibraryTag {
        if let existing = vault.tags.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        let tag = LibraryTag(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        var changed = vault
        changed.tags.append(tag)
        try commit(changed)
        return tag
    }

    func deleteTag(_ id: UUID) throws {
        var changed = vault
        changed.tags.removeAll { $0.id == id }
        for index in changed.libraryItems.indices { changed.libraryItems[index].tagIDs.remove(id) }
        try commit(changed)
    }

    func eraseEverything() throws {
        try store.eraseEverything()
        vault = VaultSnapshot()
        preferences = AppPreferences(onboardingComplete: true,
                                     appLockEnabled: preferences.appLockEnabled)
        try store.savePreferences(preferences)
    }

    private func commit(_ changed: VaultSnapshot) throws {
        try store.saveSnapshot(changed)
        vault = changed
    }
}

enum RootTab: Hashable { case journal, library, settings }
