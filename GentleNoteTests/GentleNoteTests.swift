import XCTest
@testable import GentleNote

final class GentleNoteTests: XCTestCase {
    func testEveryGuidedTemplateHasOnlyOptionalTextPrompts() {
        for template in JournalTemplateID.allCases where template != .blank {
            XCTAssertFalse(template.prompts.isEmpty)
            XCTAssertTrue(template.prompts.allSatisfy { !$0.isEmpty })
            XCTAssertFalse(template.summary.isEmpty)
        }
    }

    func testProductAvoidsQuantifiedRecoveryFields() {
        let visibleTemplateText = JournalTemplateID.allCases
            .flatMap { [$0.title, $0.intro] + $0.prompts }
            .joined(separator: " ").lowercased()
        for forbidden in ["calorie", "bmi", "macro", "weight goal", "streak", "score your", "how much did you eat"] {
            XCTAssertFalse(visibleTemplateText.contains(forbidden), "Found prohibited template phrase: \(forbidden)")
        }
    }

    func testSearchTextIncludesEveryJournalAnswer() {
        let entry = JournalEntry(templateID: .gentleCheckIn,
                                 title: "A title",
                                 answers: ["first phrase", "second phrase"])
        XCTAssertTrue(entry.searchableText.contains("first phrase"))
        XCTAssertTrue(entry.searchableText.contains("second phrase"))
    }

    func testBlankEntryDetectsEmptyAndNonemptyContent() {
        XCTAssertTrue(JournalEntry(templateID: .blank).isEmpty)
        var entry = JournalEntry(templateID: .blank)
        entry.body = "A private thought"
        XCTAssertFalse(entry.isEmpty)
    }

    func testLockDelaysAreOrdered() {
        XCTAssertEqual(LockDelay.immediately.seconds, 0)
        XCTAssertLessThan(LockDelay.oneMinute.seconds, LockDelay.fiveMinutes.seconds)
    }

    func testSpanishLocalizationIsPackaged() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try XCTUnwrap(Bundle(path: path))
        XCTAssertEqual(spanish.localizedString(forKey: "Journal", value: nil, table: nil), "Diario")
        XCTAssertEqual(spanish.localizedString(forKey: "Library", value: nil, table: nil), "Biblioteca")
        XCTAssertEqual(spanish.localizedString(forKey: "Settings", value: nil, table: nil), "Ajustes")
        XCTAssertEqual(spanish.localizedString(forKey: "Gentle Check-In", value: nil, table: nil), "Pausa para escucharte")
        XCTAssertEqual(spanish.localizedString(forKey: "Record Audio", value: nil, table: nil), "Grabar audio")
        XCTAssertEqual(spanish.localizedString(forKey: "Add Image", value: nil, table: nil), "Añadir imagen")
        XCTAssertEqual(spanish.localizedString(forKey: "Add Video", value: nil, table: nil), "Añadir vídeo")
        XCTAssertEqual(spanish.localizedString(forKey: "Add Audio", value: nil, table: nil), "Añadir audio")
        XCTAssertEqual(spanish.localizedString(forKey: "Need support?", value: nil, table: nil), "¿Necesitas apoyo?")
        XCTAssertEqual(spanish.localizedString(forKey: "Call 112", value: nil, table: nil), "Llamar al 112")
        XCTAssertEqual(spanish.localizedString(forKey: "Call 024", value: nil, table: nil), "Llamar al 024")
        XCTAssertEqual(spanish.localizedString(forKey: "Trusted Contact", value: nil, table: nil), "Contacto de confianza")
        XCTAssertEqual(spanish.localizedString(forKey: "App Language", value: nil, table: nil), "Idioma de la app")
        XCTAssertEqual(spanish.localizedString(forKey: "System Default", value: nil, table: nil), "Según el sistema")
        XCTAssertEqual(
            spanish.localizedString(forKey: "Show Library Introduction", value: nil, table: nil),
            "Mostrar la introducción de la Biblioteca"
        )
        XCTAssertEqual(
            spanish.localizedString(
                forKey: "I need some support right now. Could you call or message me when you can?",
                value: nil,
                table: nil
            ),
            "Necesito apoyo ahora mismo. ¿Puedes llamarme o escribirme cuando puedas?"
        )
    }

    func testLanguageOverrideCanForceSpanishAndEnglish() {
        defer { GentleLocalization.configure(nil) }

        GentleLocalization.configure(.spanish)
        XCTAssertEqual("Library".gentleLocalized, "Biblioteca")

        GentleLocalization.configure(.english)
        XCTAssertEqual("Library".gentleLocalized, "Library")
    }

    func testOlderPreferencesDecodeWithoutTrustedContact() throws {
        let legacyJSON = """
        {
          "onboardingComplete": true,
          "appLockEnabled": true,
          "lockDelay": "immediately",
          "showJournalPreviews": false,
          "showLibraryPreviews": false,
          "showVideoThumbnails": false,
          "showGuidedTemplates": true
        }
        """
        let preferences = try JSONDecoder().decode(AppPreferences.self, from: Data(legacyJSON.utf8))
        XCTAssertNil(preferences.trustedContact)
        XCTAssertNotEqual(preferences.requireAuthenticationForDeletion, true)
        XCTAssertNil(preferences.languageOverride)
        XCTAssertNil(preferences.showLibraryIntroduction)
    }

    func testTrustedContactRoundTrip() throws {
        var preferences = AppPreferences()
        preferences.trustedContact = TrustedContact(name: "Alex", phoneNumber: "+34123456789")
        let encoded = try JSONEncoder().encode(preferences)
        XCTAssertEqual(try JSONDecoder().decode(AppPreferences.self, from: encoded), preferences)
    }

    func testDefaultTagsAreAvailableWithoutCreatingThem() {
        let snapshot = VaultSnapshot()
        XCTAssertEqual(Set(snapshot.tags.compactMap(\.defaultKind)), Set(DefaultCollectionKind.allCases))
        XCTAssertTrue(snapshot.tags.allSatisfy { !$0.displayName.isEmpty })
    }

    func testImagesAndTagFilteringAreRepresentedInTheModel() {
        let tagID = UUID()
        var image = LibraryItem(kind: .image)
        image.tagIDs = [tagID]

        XCTAssertTrue(image.matches(.all))
        XCTAssertTrue(image.matches(.images))
        XCTAssertFalse(image.matches(.notes))
        XCTAssertTrue(image.hasTag(tagID))
        XCTAssertFalse(image.hasTag(UUID()))
        XCTAssertTrue(image.hasTag(nil))
        XCTAssertEqual(image.displayTitle, "Untitled Image".gentleLocalized)
    }

    func testLegacyCollectionsMigrateToTagsWithoutLosingAssignments() {
        let collection = LibraryCollection(name: "Words for later")
        var item = LibraryItem(kind: .note)
        item.collectionIDs = [collection.id]
        var snapshot = VaultSnapshot(schemaVersion: 1, libraryItems: [item],
                                     collections: [collection], tags: [])

        XCTAssertTrue(snapshot.migrateCollectionsToTags())
        XCTAssertEqual(snapshot.schemaVersion, 2)
        XCTAssertTrue(snapshot.collections.isEmpty)
        let migratedTag = snapshot.tags.first { $0.name == "Words for later" }
        XCTAssertNotNil(migratedTag)
        XCTAssertTrue(snapshot.libraryItems[0].collectionIDs.isEmpty)
        XCTAssertTrue(snapshot.libraryItems[0].tagIDs.contains(try! XCTUnwrap(migratedTag).id))
    }

    func testLibraryIntroductionIsVisibleUntilExplicitlyHidden() {
        let defaults = AppPreferences()
        XCTAssertNotEqual(defaults.showLibraryIntroduction, false)

        var hidden = defaults
        hidden.showLibraryIntroduction = false
        XCTAssertEqual(hidden.showLibraryIntroduction, false)
    }

    func testSpanishDefaultTagNamesArePackaged() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try XCTUnwrap(Bundle(path: path))
        XCTAssertEqual(spanish.localizedString(forKey: "Comfort", value: nil, table: nil), "Consuelo")
        XCTAssertEqual(spanish.localizedString(forKey: "Helpful Reminders", value: nil, table: nil), "Recordatorios que ayudan")
        XCTAssertEqual(spanish.localizedString(forKey: "For Difficult Moments", value: nil, table: nil), "Para momentos difíciles")
        XCTAssertEqual(spanish.localizedString(forKey: "People & Places", value: nil, table: nil), "Personas y lugares")
    }
}
