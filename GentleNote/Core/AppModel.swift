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
    @Published private(set) var activeLanguageOverride: AppLanguage?

    let store: SecureVaultStore
    let authenticator = AuthenticationService()
    private var backgroundedAt: Date?
#if DEBUG
    private var storeScreenshotPreparationFlag = false
#endif

    init() {
        do {
            store = try SecureVaultStore()
            preferences = try store.loadPreferences()
            if preferences.previewDefaultsVersion == nil {
                preferences.showJournalPreviews = true
                preferences.showLibraryPreviews = true
                preferences.showVideoThumbnails = true
                preferences.showMealReflectionPreviews = true
                preferences.previewDefaultsVersion = 1
                // Persist with the next user preference change. Avoid forcing a
                // Keychain write while an unsigned XCTest host is bootstrapping.
            }
            GentleLocalization.configure(preferences.languageOverride)
            activeLanguageOverride = preferences.languageOverride
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

    var interfaceLocale: Locale {
        activeLanguageOverride.map { Locale(identifier: $0.rawValue) } ?? .autoupdatingCurrent
    }

    var languageIdentity: String {
        activeLanguageOverride?.rawValue ?? "system-\(Locale.autoupdatingCurrent.identifier)"
    }

    var showsLibraryIntroduction: Bool {
        preferences.showLibraryIntroduction != false
    }

    var showsMealReflectionPreviews: Bool {
        preferences.showMealReflectionPreviews != false
    }

    var mealReflectionsEnabled: Bool {
        preferences.mealReflectionsEnabled != false
    }

    var showsMealReflectionIntroduction: Bool {
        preferences.showMealReflectionIntroduction != false
    }

    func setLanguage(_ language: AppLanguage?) {
        GentleLocalization.configure(language)
        preferences.languageOverride = language
        activeLanguageOverride = language
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

    func setMealReflectionIntroductionVisible(_ visible: Bool) {
        preferences.showMealReflectionIntroduction = visible
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
        activeLanguageOverride = languageOverride
        try store.savePreferences(preferences)
    }

    private func commit(_ changed: VaultSnapshot) throws {
        try store.saveSnapshot(changed)
        vault = changed
    }

}

enum RootTab: Hashable { case journal, reflections, library, settings }

#if DEBUG
enum StoreScreenshotScenario: String {
    case journal, templates, library, intakes, settings, privacy
}

struct StoreScreenshotConfiguration {
    let scenario: StoreScreenshotScenario
    let language: AppLanguage

    static var current: StoreScreenshotConfiguration? {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        let fixture = fileFixture
        let scenarioValue = fixture?.scenario ?? environment["GNStoreScreenshot"] ?? value(after: "-GNStoreScreenshot", in: arguments)
        guard let scenarioValue,
              let scenario = StoreScreenshotScenario(rawValue: scenarioValue) else { return nil }
        let language: AppLanguage
        let languageValue = fixture?.language ?? environment["GNStoreLanguage"] ?? value(after: "-GNStoreLanguage", in: arguments)
        if let languageValue,
           let requested = AppLanguage(rawValue: languageValue) {
            language = requested
        } else {
            language = .english
        }
        return StoreScreenshotConfiguration(scenario: scenario, language: language)
    }

    private static var fileFixture: (scenario: String, language: String)? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = try? Data(contentsOf: documents.appendingPathComponent("store-screenshot.json")),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let scenario = object["scenario"],
              let language = object["language"] else { return nil }
        return (scenario, language)
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

extension AppModel {
    func prepareStoreScreenshot(_ configuration: StoreScreenshotConfiguration) {
        guard !storeScreenshotPreparationFlag else { return }
        storeScreenshotPreparationFlag = true

        let language = configuration.language
        let localized: (String, String) -> String = { english, spanish in
            language == .spanish ? spanish : english
        }
        var tags = LibraryTag.defaults
        let helpfulTag = tags.first(where: { $0.defaultKind == .helpfulReminders })?.id
        let comfortTag = tags.first(where: { $0.defaultKind == .comfort })?.id
        let now = Date()
        let journalEntries = [
            JournalEntry(templateID: .noticeSomethingSmall,
                         title: localized("A small moment I want to remember", "Un momento pequeño que quiero recordar"),
                         body: localized("I asked for support and gave myself some quiet time.",
                                         "Pedí apoyo y me permití un poco de calma."),
                         isKept: true,
                         createdAt: now.addingTimeInterval(-3_600),
                         updatedAt: now.addingTimeInterval(-3_600)),
            JournalEntry(templateID: .gentleCheckIn,
                         title: localized("What I need today", "Lo que necesito hoy"),
                         body: localized("A gentler pace and a conversation with someone I trust.",
                                         "Un ritmo más amable y hablar con alguien de confianza."),
                         createdAt: now.addingTimeInterval(-86_400),
                         updatedAt: now.addingTimeInterval(-86_400))
        ]
        let libraryItems = [
            LibraryItem(kind: .note,
                        title: localized("Words I want to keep", "Palabras que quiero conservar"),
                        body: localized("I do not have to handle every difficult moment alone.",
                                        "No tengo que atravesar a solas cada momento difícil."),
                        tagIDs: Set([helpfulTag].compactMap { $0 }),
                        isKept: true,
                        createdAt: now.addingTimeInterval(-7_200),
                        updatedAt: now.addingTimeInterval(-7_200)),
            LibraryItem(kind: .note,
                        title: localized("For a difficult moment", "Para un momento difícil"),
                        body: localized("Pause, breathe, and message someone I trust.",
                                        "Pausa, respira y escribe a alguien de confianza."),
                        tagIDs: Set([comfortTag].compactMap { $0 }),
                        createdAt: now.addingTimeInterval(-172_800),
                        updatedAt: now.addingTimeInterval(-172_800))
        ]

        preferences = AppPreferences(onboardingComplete: true,
                                     appLockEnabled: false,
                                     languageOverride: language,
                                     showLibraryIntroduction: true,
                                     showMealReflectionPreviews: true,
                                     mealReflectionsEnabled: true,
                                     showMealReflectionIntroduction: true,
                                     previewDefaultsVersion: 1)
        vault = VaultSnapshot(journalEntries: journalEntries,
                              libraryItems: libraryItems,
                              tags: tags)
        GentleLocalization.configure(language)
        activeLanguageOverride = language
        isUnlocked = true
        privacyCoverVisible = false
        selectedTab = switch configuration.scenario {
        case .library: .library
        case .intakes: .reflections
        case .settings: .settings
        default: .journal
        }
    }
}
#endif
