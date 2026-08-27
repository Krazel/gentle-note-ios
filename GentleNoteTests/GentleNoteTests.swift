import XCTest
@testable import GentleNote

final class GentleNoteTests: XCTestCase {
    func testEveryGuidedTemplateHasOnlyOptionalTextPrompts() {
        for template in JournalTemplateID.allCases where template != .blank {
            XCTAssertFalse(template.prompts.isEmpty)
            XCTAssertTrue(template.prompts.allSatisfy { !$0.isEmpty })
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
        XCTAssertEqual(spanish.localizedString(forKey: "Call 112", value: nil, table: nil), "Llamar al 112")
        XCTAssertEqual(spanish.localizedString(forKey: "Call 024", value: nil, table: nil), "Llamar al 024")
        XCTAssertEqual(spanish.localizedString(forKey: "Trusted Contact", value: nil, table: nil), "Contacto de confianza")
        XCTAssertEqual(
            spanish.localizedString(
                forKey: "I need some support right now. Could you call or message me when you can?",
                value: nil,
                table: nil
            ),
            "Necesito apoyo ahora mismo. ¿Puedes llamarme o escribirme cuando puedas?"
        )
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
    }

    func testTrustedContactRoundTrip() throws {
        var preferences = AppPreferences()
        preferences.trustedContact = TrustedContact(name: "Alex", phoneNumber: "+34123456789")
        let encoded = try JSONEncoder().encode(preferences)
        XCTAssertEqual(try JSONDecoder().decode(AppPreferences.self, from: encoded), preferences)
    }
}
