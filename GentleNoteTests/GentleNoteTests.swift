import XCTest
import AVFoundation
@testable import GentleNote

final class GentleNoteTests: XCTestCase {
    func testFirstRunFlowPlacesOverviewBetweenWelcomeAndAppLock() {
        XCTAssertEqual(OnboardingStep.allCases, [.welcome, .overview, .appLock])

        var flow = OnboardingFlowState()
        XCTAssertEqual(flow.step, .welcome)
        flow.advance()
        XCTAssertEqual(flow.step, .overview)
        flow.advance()
        XCTAssertEqual(flow.step, .appLock)
    }

    func testSkipAndContinueReachAppLockWithoutCompletingOnboardingOrChangingLock() {
        let preferences = AppPreferences()
        let initialLockSetting = preferences.appLockEnabled

        var continued = OnboardingFlowState()
        continued.advance()
        continued.advance()
        XCTAssertEqual(continued.step, .appLock)

        var skipped = OnboardingFlowState()
        skipped.skipTour()
        XCTAssertEqual(skipped.step, .welcome)
        skipped.advance()
        skipped.skipTour()
        XCTAssertEqual(skipped.step, .appLock)

        XCTAssertFalse(preferences.onboardingComplete)
        XCTAssertEqual(preferences.appLockEnabled, initialLockSetting)
    }

    func testFirstRunOverviewAlwaysContainsThreeOrderedSpaces() {
        XCTAssertEqual(onboardingOverviewItems.map(\.title), ["Journal", "Library", "Intakes"])
        XCTAssertEqual(onboardingOverviewItems.count, 3)
        XCTAssertEqual(
            onboardingOverviewItems.last?.body,
            "Keep one or more photos of your meals together with any words, audio, or video you want to add."
        )
    }

    func testEveryContentPreviewStartsEnabled() {
        let preferences = AppPreferences()
        XCTAssertTrue(preferences.showJournalPreviews)
        XCTAssertTrue(preferences.showLibraryPreviews)
        XCTAssertTrue(preferences.showVideoThumbnails)
        XCTAssertEqual(preferences.showMealReflectionPreviews, true)
    }

    @MainActor
    func testAudioRecorderUsesACompatibleRecordingSession() {
        XCTAssertEqual(AudioRecorder.sessionCategory.rawValue, AVAudioSession.Category.record.rawValue)
        XCTAssertEqual(AudioRecorder.sessionMode.rawValue, AVAudioSession.Mode.default.rawValue)
    }

    func testEveryGuidedTemplateHasOnlyOptionalTextPrompts() {
        for template in JournalTemplateID.allCases where template != .blank {
            XCTAssertFalse(template.prompts.isEmpty)
            XCTAssertTrue(template.prompts.allSatisfy { !$0.isEmpty })
            XCTAssertFalse(template.summary.isEmpty)
        }
    }

    func testProductAvoidsQuantifiedRecoveryFields() {
        let visibleTemplateText = JournalTemplateID.allCases
            .flatMap { [$0.title] + [$0.intro].compactMap { $0 } + $0.prompts }
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
        XCTAssertEqual(
            spanish.localizedString(forKey: "Three spaces, each with its own purpose.", value: nil, table: nil),
            "Tres espacios, cada uno con su propósito."
        )
        XCTAssertEqual(spanish.localizedString(forKey: "Intakes", value: nil, table: nil), "Ingestas")
        XCTAssertEqual(
            spanish.localizedString(
                forKey: "Keep private notes, images, videos, and audio to return to whenever you choose.",
                value: nil,
                table: nil
            ),
            "Guarda notas, imágenes, vídeos y audios privados para volver a ellos cuando tú decidas."
        )
        XCTAssertEqual(
            spanish.localizedString(forKey: "Write a note to return to later…", value: nil, table: nil),
            "Escribe una nota a la que quieras volver más adelante…"
        )
        XCTAssertEqual(spanish.localizedString(forKey: "Skip tour", value: nil, table: nil), "Omitir recorrido")
        XCTAssertEqual(
            spanish.localizedString(forKey: "Continue to App Lock", value: nil, table: nil),
            "Continuar al bloqueo"
        )
        XCTAssertEqual(spanish.localizedString(forKey: "Need support?", value: nil, table: nil), "¿Necesitas apoyo?")
        XCTAssertEqual(spanish.localizedString(forKey: "Call 112", value: nil, table: nil), "Llamar al 112")
        XCTAssertEqual(spanish.localizedString(forKey: "Call 024", value: nil, table: nil), "Llamar al 024")
        XCTAssertEqual(spanish.localizedString(forKey: "Trusted Contact", value: nil, table: nil), "Contacto de confianza")
        XCTAssertEqual(spanish.localizedString(forKey: "App Language", value: nil, table: nil), "Idioma de la app")
        XCTAssertEqual(spanish.localizedString(forKey: "System Default", value: nil, table: nil), "Según el sistema")
        XCTAssertEqual(
            spanish.localizedString(forKey: "What Library is for", value: nil, table: nil),
            "Para qué sirve la Biblioteca"
        )
        XCTAssertEqual(
            spanish.localizedString(forKey: "What Intakes is for", value: nil, table: nil),
            "Para qué sirven las Ingestas"
        )
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

    func testEnglishLocalizationIsPackagedForRuntimeSwitching() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let english = try XCTUnwrap(Bundle(path: path))
        XCTAssertEqual(english.localizedString(forKey: "Journal", value: nil, table: nil), "Journal")
        XCTAssertEqual(english.localizedString(forKey: "Library", value: nil, table: nil), "Library")
        XCTAssertEqual(english.localizedString(forKey: "Intakes", value: nil, table: nil), "Intakes")
        XCTAssertTrue(Bundle.main.localizations.contains("en"))
        XCTAssertTrue(Bundle.main.localizations.contains("es"))
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
        XCTAssertNil(preferences.showMealReflectionPreviews)
        XCTAssertNil(preferences.mealReflectionsEnabled)
        XCTAssertNil(preferences.showMealReflectionIntroduction)
        XCTAssertNil(preferences.previewDefaultsVersion)
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
        XCTAssertEqual(snapshot.schemaVersion, 3)
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

    func testOlderVaultDecodesWithAnEmptyMealReflectionsSection() throws {
        let legacyJSON = """
        {
          "schemaVersion": 2,
          "journalEntries": [],
          "libraryItems": [],
          "collections": [],
          "tags": []
        }
        """
        var snapshot = try JSONDecoder.gentle.decode(VaultSnapshot.self, from: Data(legacyJSON.utf8))
        XCTAssertTrue(snapshot.mealReflections.isEmpty)
        XCTAssertTrue(snapshot.migrateCollectionsToTags())
        XCTAssertEqual(snapshot.schemaVersion, 3)
    }

    func testMealReflectionKeepsItsMainPhotoAndCombinedAttachments() {
        let image = ReflectionAttachment(kind: .image,
                                         encryptedMediaFilename: "additional.gnm",
                                         mediaFileExtension: "jpg")
        let audio = ReflectionAttachment(kind: .audio,
                                         encryptedMediaFilename: "voice.gnm",
                                         mediaFileExtension: "m4a")
        let video = ReflectionAttachment(kind: .video,
                                         encryptedMediaFilename: "clip.gnm",
                                         mediaFileExtension: "mov")
        let reflection = MealReflection(mainPhotoFilename: "main.gnm",
                                        mainPhotoExtension: "jpg",
                                        attachments: [image, audio, video],
                                        mealMoment: .lunch)
        XCTAssertEqual(reflection.mealMoment, .lunch)
        XCTAssertEqual(reflection.attachments.map(\.kind), [.image, .audio, .video])
        XCTAssertEqual(reflection.allMediaFilenames,
                       ["main.gnm", "additional.gnm", "voice.gnm", "clip.gnm"])
    }

    func testIntakeGuideUsesQualitativeDocumentedPrompts() {
        XCTAssertEqual(IntakeGuidePrompt.allCases.count, 5)
        let text = IntakeGuidePrompt.allCases.map(\.question).joined(separator: " ").lowercased()
        for forbidden in ["calorie", "weight", "bmi", "macro", "how much", "score"] {
            XCTAssertFalse(text.contains(forbidden), "Found quantified intake phrase: \(forbidden)")
        }
    }

    func testOlderMealReflectionDecodesWithoutGuidedAnswers() throws {
        let json = """
        {
          "id": "48EBA538-7D5A-49C6-8F6F-83B7AA104A40",
          "mainPhotoFilename": "main.gnm",
          "mainPhotoExtension": "jpg",
          "words": "Existing words",
          "attachments": [],
          "reflectionDate": "2026-08-31T10:00:00Z",
          "createdAt": "2026-08-31T10:00:00Z",
          "updatedAt": "2026-08-31T10:00:00Z"
        }
        """
        let intake = try JSONDecoder.gentle.decode(MealReflection.self, from: Data(json.utf8))
        XCTAssertTrue(intake.guidedAnswers.isEmpty)
        XCTAssertEqual(intake.words, "Existing words")
    }

    func testSpanishDefaultTagNamesArePackaged() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try XCTUnwrap(Bundle(path: path))
        XCTAssertEqual(spanish.localizedString(forKey: "Comfort", value: nil, table: nil), "Consuelo")
        XCTAssertEqual(spanish.localizedString(forKey: "Helpful Reminders", value: nil, table: nil), "Recordatorios que ayudan")
        XCTAssertEqual(spanish.localizedString(forKey: "For Difficult Moments", value: nil, table: nil), "Para momentos difíciles")
        XCTAssertEqual(spanish.localizedString(forKey: "People & Places", value: nil, table: nil), "Personas y lugares")
        XCTAssertEqual(spanish.localizedString(forKey: "Breakfast", value: nil, table: nil), "Desayuno")
        XCTAssertEqual(spanish.localizedString(forKey: "Morning snack", value: nil, table: nil), "Tentempié")
        XCTAssertEqual(spanish.localizedString(forKey: "Lunch", value: nil, table: nil), "Comida")
        XCTAssertEqual(spanish.localizedString(forKey: "Afternoon snack", value: nil, table: nil), "Merienda")
        XCTAssertEqual(spanish.localizedString(forKey: "Dinner", value: nil, table: nil), "Cena")
    }
}
