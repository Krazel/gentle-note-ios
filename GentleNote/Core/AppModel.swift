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
            GentleLocalization.configure(preferences.languageOverride)
            var loadedVault = try store.loadSnapshot()
            if loadedVault.migrateCollectionsToTags() {
                try store.saveSnapshot(loadedVault)
            }
            vault = loadedVault
            isUnlocked = !preferences.appLockEnabled
        } catch {
            fatalError("Gentle Note could not initialize private storage: \(error.localizedDescription)")
        }
    }

    func savePreferences() {
        do { try store.savePreferences(preferences) }
        catch { lastError = error.localizedDescription }
    }

    var interfaceLocale: Locale { GentleLocalization.locale }

    var languageIdentity: String {
        preferences.languageOverride?.rawValue ?? "system-\(Locale.autoupdatingCurrent.identifier)"
    }

    var showsLibraryIntroduction: Bool {
        preferences.showLibraryIntroduction != false
    }

    var showsMealReflectionPreviews: Bool {
        preferences.showMealReflectionPreviews == true
    }

    var mealReflectionsEnabled: Bool {
        preferences.mealReflectionsEnabled != false
    }

    func setLanguage(_ language: AppLanguage?) {
        preferences.languageOverride = language
        GentleLocalization.configure(language)
        savePreferences()
    }

    func setLibraryIntroductionVisible(_ visible: Bool) {
        preferences.showLibraryIntroduction = visible
        savePreferences()
    }

    func setMealReflectionPreviewsVisible(_ visible: Bool) {
        preferences.showMealReflectionPreviews = visible
        savePreferences()
    }

    func setMealReflectionsEnabled(_ enabled: Bool) {
        preferences.mealReflectionsEnabled = enabled
        if !enabled, selectedTab == .reflections { selectedTab = .journal }
        savePreferences()
    }

    func setOnboardingComplete() {
        preferences.onboardingComplete = true
        savePreferences()
    }

    func unlock(reason: String = "Unlock your private space.".gentleLocalized) async -> Bool {
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

    func authorizeDeletion(reason: String) async -> Bool {
        guard preferences.appLockEnabled,
              preferences.requireAuthenticationForDeletion == true else { return true }
        return await authenticator.authenticate(reason: reason)
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

    func saveMealReflection(_ reflection: MealReflection,
                            newlyImportedFilenames: Set<String> = []) throws {
        var changed = vault
        let previous = changed.mealReflections.first { $0.id == reflection.id }
        if let index = changed.mealReflections.firstIndex(where: { $0.id == reflection.id }) {
            changed.mealReflections[index] = reflection
        } else {
            changed.mealReflections.append(reflection)
        }
        do {
            try commit(changed)
        } catch {
            for filename in newlyImportedFilenames { try? store.removeMedia(filename: filename) }
            throw error
        }
        let obsolete = (previous?.allMediaFilenames ?? []).subtracting(reflection.allMediaFilenames)
        for filename in obsolete { try? store.removeMedia(filename: filename) }
    }

    func deleteMealReflection(_ id: UUID) throws {
        var changed = vault
        guard let reflection = changed.mealReflections.first(where: { $0.id == id }) else { return }
        changed.mealReflections.removeAll { $0.id == id }
        try commit(changed)
        for filename in reflection.allMediaFilenames { try? store.removeMedia(filename: filename) }
    }

    func addTag(named name: String) throws -> LibraryTag {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = vault.tags.first(where: { $0.displayName.caseInsensitiveCompare(cleanName) == .orderedSame }) {
            return existing
        }
        let tag = LibraryTag(name: cleanName)
        var changed = vault
        changed.tags.append(tag)
        try commit(changed)
        return tag
    }

    func renameTag(_ id: UUID, to name: String) throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty,
              !vault.tags.contains(where: { $0.id != id && $0.displayName.caseInsensitiveCompare(cleanName) == .orderedSame }) else { return }
        var changed = vault
        guard let index = changed.tags.firstIndex(where: { $0.id == id }),
              changed.tags[index].defaultKind == nil else { return }
        changed.tags[index].name = cleanName
        try commit(changed)
    }

    func deleteTag(_ id: UUID) throws {
        var changed = vault
        guard changed.tags.first(where: { $0.id == id })?.defaultKind == nil else { return }
        changed.tags.removeAll { $0.id == id }
        for index in changed.libraryItems.indices { changed.libraryItems[index].tagIDs.remove(id) }
        changed.libraryDraft?.tagIDs.remove(id)
        try commit(changed)
    }

    func eraseEverything() throws {
        let languageOverride = preferences.languageOverride
        try store.eraseEverything()
        vault = VaultSnapshot()
        preferences = AppPreferences(onboardingComplete: true,
                                     appLockEnabled: preferences.appLockEnabled,
                                     languageOverride: languageOverride)
        GentleLocalization.configure(languageOverride)
        try store.savePreferences(preferences)
    }

    private func commit(_ changed: VaultSnapshot) throws {
        try store.saveSnapshot(changed)
        vault = changed
    }

}

enum RootTab: Hashable { case journal, reflections, library, settings }
