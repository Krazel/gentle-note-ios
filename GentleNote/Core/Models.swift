import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English".gentleLocalized
        case .spanish: "Spanish".gentleLocalized
        }
    }
}

enum GentleLocalization {
    private static let lock = NSLock()
    private static var selectedLanguage: AppLanguage?

    static func configure(_ language: AppLanguage?) {
        lock.lock()
        selectedLanguage = language
        lock.unlock()
    }

    static var language: AppLanguage? {
        lock.lock()
        defer { lock.unlock() }
        return selectedLanguage
    }

    static var locale: Locale {
        language.map { Locale(identifier: $0.rawValue) } ?? .autoupdatingCurrent
    }

    static var bundle: Bundle {
        guard let code = language?.rawValue,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    static func localizedString(for key: String) -> String {
        if language == .english { return key }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
}

extension String {
    var gentleLocalized: String {
        GentleLocalization.localizedString(for: self)
    }

    func gentleLocalizedFormat(_ arguments: CVarArg...) -> String {
        String(format: gentleLocalized, locale: GentleLocalization.locale, arguments: arguments)
    }
}

enum JournalTemplateID: String, Codable, CaseIterable, Identifiable {
    case blank
    case gentleCheckIn
    case balancedThought
    case selfCompassionPause
    case valuesCompass
    case presentMoment
    case prepareToTalk
    case noticeSomethingSmall

    var id: String { rawValue }

    var title: String {
        let key = switch self {
        case .blank: "Blank Entry"
        case .gentleCheckIn: "Gentle Check-In"
        case .balancedThought: "A Balanced Thought"
        case .selfCompassionPause: "Self-Compassion Pause"
        case .valuesCompass: "Values Compass"
        case .presentMoment: "Present-Moment Reflection"
        case .prepareToTalk: "Prepare to Talk"
        case .noticeSomethingSmall: "Notice Something Small"
        }
        return key.gentleLocalized
    }

    var subtitle: String? {
        let key: String? = switch self {
        case .balancedThought: "CBT-inspired"
        case .valuesCompass: "Values-based"
        case .presentMoment: "Grounding-inspired"
        default: nil
        }
        return key?.gentleLocalized
    }

    var icon: String {
        switch self {
        case .blank: "square.and.pencil"
        case .gentleCheckIn: "leaf"
        case .balancedThought: "scale.3d"
        case .selfCompassionPause: "hands.sparkles"
        case .valuesCompass: "safari"
        case .presentMoment: "camera.macro"
        case .prepareToTalk: "heart.text.square"
        case .noticeSomethingSmall: "sparkles"
        }
    }

    var intro: String? {
        let key: String? = switch self {
        case .blank: nil
        case .gentleCheckIn: "Use this when you want to understand a moment by noticing what happened, what you felt, and what you needed."
        case .balancedThought: "Use this when one thought feels especially strong and you want to examine it from more than one angle."
        case .selfCompassionPause: "Use this when you are being hard on yourself or carrying a difficult moment."
        case .valuesCompass: "Use this when you feel pulled off course and want to reconnect with what matters."
        case .presentMoment: "Use this when you feel overwhelmed, disconnected, or caught in thoughts and want to return to the present."
        case .prepareToTalk: "Use this before talking with someone you trust or your care team about what is happening and what support you want."
        case .noticeSomethingSmall: "Use this when you want to remember a small act of care, honesty, flexibility, or courage."
        }
        return key?.gentleLocalized
    }

    var summary: String {
        let key = switch self {
        case .blank:
            "Write in your own way, without prompts or structure."
        case .gentleCheckIn:
            "Sort through what happened, what you noticed, what you needed, and what helped."
        case .balancedThought:
            "Look at a difficult thought from more than one angle and make room for a steadier view."
        case .selfCompassionPause:
            "Meet a difficult moment with the kindness you might offer someone you care about."
        case .valuesCompass:
            "Reconnect with what matters to you and consider one small action that reflects it."
        case .presentMoment:
            "Notice your surroundings, your body, and what feels steady without trying to fix anything."
        case .prepareToTalk:
            "Organize what you want someone to understand and the support you may want to ask for."
        case .noticeSomethingSmall:
            "Remember a small moment of care, honesty, flexibility, or courage."
        }
        return key.gentleLocalized
    }

    var prompts: [String] {
        let keys: [String] = switch self {
        case .blank:
            []
        case .gentleCheckIn:
            ["What happened?",
             "What did you notice—thoughts, feelings, sensations, or context?",
             "What did you need then? What do you need now?",
             "What helped, even a little?",
             "Is there something you want to acknowledge?"]
        case .balancedThought:
            ["What happened?",
             "What did you notice in your thoughts, feelings, or body?",
             "What seems to support the thought?",
             "What does not fully fit the thought?",
             "Is there a more balanced or neutral way to see this?",
             "What do you notice now?"]
        case .selfCompassionPause:
            ["What feels difficult right now?",
             "How might you remember that struggling is human?",
             "What would you say to someone you care about?",
             "What kind words do you need right now?"]
        case .valuesCompass:
            ["What matters to you in this situation?",
             "What kind of person do you want to be here?",
             "What small action could reflect that value?",
             "What thoughts or feelings might you need to make room for?"]
        case .presentMoment:
            ["What can you notice around you?",
             "What can you notice in your body, without needing to change it?",
             "What feels steady or supportive right now?",
             "What is a gentle next step, if any?"]
        case .prepareToTalk:
            ["What do you want someone to understand?",
             "What would you like support with?",
             "Is there anything you are not ready to discuss yet?",
             "Is there an entry you may want to share?"]
        case .noticeSomethingSmall:
            ["Is there a small act of care, honesty, flexibility, or courage you’d like to notice?",
             "What helped make room for it?"]
        }
        return keys.map { $0.gentleLocalized }
    }
}

struct JournalEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var templateID: JournalTemplateID
    var title = ""
    var body = ""
    var answers: [String] = []
    var isKept = false
    var createdAt = Date()
    var updatedAt = Date()

    var displayTitle: String {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? templateID.title : clean
    }

    var searchableText: String {
        ([displayTitle, body] + answers).joined(separator: " ")
    }

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        answers.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

enum LibraryItemKind: String, Codable, CaseIterable, Identifiable {
    case note, image, video, audio
    var id: String { rawValue }
    var title: String {
        switch self {
        case .note: "Note".gentleLocalized
        case .image: "Image".gentleLocalized
        case .video: "Video".gentleLocalized
        case .audio: "Audio".gentleLocalized
        }
    }
    var icon: String {
        switch self {
        case .note: "doc"
        case .image: "photo.fill"
        case .video: "video.fill"
        case .audio: "mic.fill"
        }
    }
}

struct LibraryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: LibraryItemKind
    var title = ""
    var body = ""
    var encryptedMediaFilename: String?
    var mediaFileExtension: String?
    var duration: TimeInterval?
    var collectionIDs: Set<UUID> = []
    var tagIDs: Set<UUID> = []
    var isKept = false
    var createdAt = Date()
    var updatedAt = Date()

    var displayTitle: String {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty { return clean }
        return switch kind {
        case .note: "Untitled Note".gentleLocalized
        case .image: "Untitled Image".gentleLocalized
        case .video: "Untitled Video".gentleLocalized
        case .audio: "Untitled Audio".gentleLocalized
        }
    }

    func matches(_ filter: LibraryFilter) -> Bool {
        switch filter {
        case .all: true
        case .notes: kind == .note
        case .images: kind == .image
        case .videos: kind == .video
        case .audio: kind == .audio
        case .kept: isKept
        }
    }

    func hasTag(_ tagID: UUID?) -> Bool {
        guard let tagID else { return true }
        return tagIDs.contains(tagID)
    }
}

enum MealMoment: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case morningSnack
    case lunch
    case afternoonSnack
    case dinner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: "Breakfast".gentleLocalized
        case .morningSnack: "Morning snack".gentleLocalized
        case .lunch: "Lunch".gentleLocalized
        case .afternoonSnack: "Afternoon snack".gentleLocalized
        case .dinner: "Dinner".gentleLocalized
        }
    }
}

enum ReflectionAttachmentKind: String, Codable, CaseIterable, Identifiable {
    case image, audio, video

    var id: String { rawValue }

    var title: String {
        switch self {
        case .image: "Image".gentleLocalized
        case .audio: "Audio".gentleLocalized
        case .video: "Video".gentleLocalized
        }
    }

    var icon: String {
        switch self {
        case .image: "photo"
        case .audio: "waveform"
        case .video: "video"
        }
    }

    var libraryKind: LibraryItemKind {
        switch self {
        case .image: .image
        case .audio: .audio
        case .video: .video
        }
    }
}

struct ReflectionAttachment: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: ReflectionAttachmentKind
    var encryptedMediaFilename: String
    var mediaFileExtension: String
    var duration: TimeInterval?
    var createdAt = Date()
}

struct MealReflection: Identifiable, Codable, Hashable {
    var id = UUID()
    var mainPhotoFilename: String
    var mainPhotoExtension: String
    var words = ""
    var guidedAnswers: [String] = []
    var attachments: [ReflectionAttachment] = []
    var reflectionDate = Date()
    var mealMoment: MealMoment?
    var createdAt = Date()
    var updatedAt = Date()

    var displayTitle: String {
        mealMoment?.title ?? "Intake".gentleLocalized
    }

    var allMediaFilenames: Set<String> {
        Set([mainPhotoFilename] + attachments.map(\.encryptedMediaFilename))
    }

    private enum CodingKeys: String, CodingKey {
        case id, mainPhotoFilename, mainPhotoExtension, words, guidedAnswers, attachments,
             reflectionDate, mealMoment, createdAt, updatedAt
    }

    init(id: UUID = UUID(),
         mainPhotoFilename: String,
         mainPhotoExtension: String,
         words: String = "",
         guidedAnswers: [String] = [],
         attachments: [ReflectionAttachment] = [],
         reflectionDate: Date = Date(),
         mealMoment: MealMoment? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.mainPhotoFilename = mainPhotoFilename
        self.mainPhotoExtension = mainPhotoExtension
        self.words = words
        self.guidedAnswers = guidedAnswers
        self.attachments = attachments
        self.reflectionDate = reflectionDate
        self.mealMoment = mealMoment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        mainPhotoFilename = try container.decode(String.self, forKey: .mainPhotoFilename)
        mainPhotoExtension = try container.decode(String.self, forKey: .mainPhotoExtension)
        words = try container.decodeIfPresent(String.self, forKey: .words) ?? ""
        guidedAnswers = try container.decodeIfPresent([String].self, forKey: .guidedAnswers) ?? []
        attachments = try container.decodeIfPresent([ReflectionAttachment].self, forKey: .attachments) ?? []
        reflectionDate = try container.decodeIfPresent(Date.self, forKey: .reflectionDate) ?? Date()
        mealMoment = try container.decodeIfPresent(MealMoment.self, forKey: .mealMoment)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

enum IntakeGuidePrompt: String, CaseIterable, Identifiable {
    case context
    case thoughtsAndFeelings
    case difficultOrSupportive
    case needs
    case rememberOrShare

    var id: String { rawValue }

    var question: String {
        let key = switch self {
        case .context: "What was happening around this intake?"
        case .thoughtsAndFeelings: "What thoughts, feelings, or body sensations showed up?"
        case .difficultOrSupportive: "What felt difficult or supportive?"
        case .needs: "What did you need in that moment?"
        case .rememberOrShare: "What would you like to remember or bring to someone you trust?"
        }
        return key.gentleLocalized
    }
}

enum CollectionSymbol: String, Codable, CaseIterable, Identifiable {
    case leaf = "leaf"
    case sprig = "camera.macro"
    case flower = "camera.macro.circle"
    case sun = "sun.max"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .leaf: "Leaf".gentleLocalized
        case .sprig: "Sprig".gentleLocalized
        case .flower: "Flower".gentleLocalized
        case .sun: "Sun".gentleLocalized
        }
    }
}

enum CollectionColor: String, Codable, CaseIterable, Identifiable {
    case forest, sage, ochre, clay
    var id: String { rawValue }
    var title: String {
        switch self {
        case .forest: "Forest".gentleLocalized
        case .sage: "Sage".gentleLocalized
        case .ochre: "Ochre".gentleLocalized
        case .clay: "Clay".gentleLocalized
        }
    }
}

struct LibraryCollection: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var symbol: CollectionSymbol = .leaf
    var color: CollectionColor = .forest
    var createdAt = Date()
    var defaultKind: DefaultCollectionKind? = nil

    var displayName: String { defaultKind?.title ?? name }

    static var defaults: [LibraryCollection] {
        DefaultCollectionKind.allCases.map {
            LibraryCollection(name: "", symbol: $0.symbol, color: $0.color, defaultKind: $0)
        }
    }
}

enum DefaultCollectionKind: String, Codable, CaseIterable {
    case comfort
    case helpfulReminders
    case difficultMoments
    case peopleAndPlaces

    var title: String {
        switch self {
        case .comfort: "Comfort".gentleLocalized
        case .helpfulReminders: "Helpful Reminders".gentleLocalized
        case .difficultMoments: "For Difficult Moments".gentleLocalized
        case .peopleAndPlaces: "People & Places".gentleLocalized
        }
    }

    var symbol: CollectionSymbol {
        switch self {
        case .comfort: .flower
        case .helpfulReminders: .leaf
        case .difficultMoments: .sprig
        case .peopleAndPlaces: .sun
        }
    }

    var color: CollectionColor {
        switch self {
        case .comfort: .clay
        case .helpfulReminders: .sage
        case .difficultMoments: .forest
        case .peopleAndPlaces: .ochre
        }
    }
}

struct LibraryTag: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var defaultKind: DefaultCollectionKind? = nil

    var displayName: String { defaultKind?.title ?? name }

    static var defaults: [LibraryTag] {
        DefaultCollectionKind.allCases.map {
            LibraryTag(name: "", defaultKind: $0)
        }
    }
}

struct JournalDraft: Codable, Equatable {
    var templateID: JournalTemplateID
    var title: String
    var body: String
    var answers: [String]
    var isKept: Bool
    var savedAt: Date
}

struct LibraryDraft: Codable, Equatable {
    var title: String
    var body: String
    var isKept: Bool
    var collectionIDs: Set<UUID>
    var tagIDs: Set<UUID>
    var savedAt: Date
}

struct VaultSnapshot: Codable, Equatable {
    var schemaVersion = 3
    var journalEntries: [JournalEntry] = []
    var libraryItems: [LibraryItem] = []
    var mealReflections: [MealReflection] = []
    // Kept only to decode and migrate vaults created before tags replaced collections.
    var collections: [LibraryCollection] = []
    var tags: [LibraryTag] = LibraryTag.defaults
    var journalDraft: JournalDraft?
    var libraryDraft: LibraryDraft?

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, journalEntries, libraryItems, mealReflections, collections, tags,
             journalDraft, libraryDraft
    }

    init(schemaVersion: Int = 3,
         journalEntries: [JournalEntry] = [],
         libraryItems: [LibraryItem] = [],
         mealReflections: [MealReflection] = [],
         collections: [LibraryCollection] = [],
         tags: [LibraryTag] = LibraryTag.defaults,
         journalDraft: JournalDraft? = nil,
         libraryDraft: LibraryDraft? = nil) {
        self.schemaVersion = schemaVersion
        self.journalEntries = journalEntries
        self.libraryItems = libraryItems
        self.mealReflections = mealReflections
        self.collections = collections
        self.tags = tags
        self.journalDraft = journalDraft
        self.libraryDraft = libraryDraft
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        journalEntries = try container.decodeIfPresent([JournalEntry].self, forKey: .journalEntries) ?? []
        libraryItems = try container.decodeIfPresent([LibraryItem].self, forKey: .libraryItems) ?? []
        mealReflections = try container.decodeIfPresent([MealReflection].self, forKey: .mealReflections) ?? []
        collections = try container.decodeIfPresent([LibraryCollection].self, forKey: .collections) ?? []
        tags = try container.decodeIfPresent([LibraryTag].self, forKey: .tags) ?? LibraryTag.defaults
        journalDraft = try container.decodeIfPresent(JournalDraft.self, forKey: .journalDraft)
        libraryDraft = try container.decodeIfPresent(LibraryDraft.self, forKey: .libraryDraft)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(journalEntries, forKey: .journalEntries)
        try container.encode(libraryItems, forKey: .libraryItems)
        try container.encode(mealReflections, forKey: .mealReflections)
        try container.encode(collections, forKey: .collections)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(journalDraft, forKey: .journalDraft)
        try container.encodeIfPresent(libraryDraft, forKey: .libraryDraft)
    }
}

extension VaultSnapshot {
    @discardableResult
    mutating func migrateCollectionsToTags() -> Bool {
        var changed = schemaVersion < 3 || !collections.isEmpty
        var collectionToTag: [UUID: UUID] = [:]

        for collection in collections {
            let existing = tags.first { tag in
                if let kind = collection.defaultKind { return tag.defaultKind == kind }
                return tag.displayName.caseInsensitiveCompare(collection.displayName) == .orderedSame
            }
            if let existing {
                collectionToTag[collection.id] = existing.id
            } else {
                let tag = LibraryTag(name: collection.defaultKind == nil ? collection.name : "",
                                     createdAt: collection.createdAt,
                                     defaultKind: collection.defaultKind)
                tags.append(tag)
                collectionToTag[collection.id] = tag.id
                changed = true
            }
        }

        let missingDefaults = DefaultCollectionKind.allCases.filter { kind in
            !tags.contains { $0.defaultKind == kind }
        }
        for kind in missingDefaults {
            tags.append(LibraryTag(name: "", defaultKind: kind))
            changed = true
        }

        for index in libraryItems.indices {
            let migrated = libraryItems[index].collectionIDs.compactMap { collectionToTag[$0] }
            if !migrated.isEmpty || !libraryItems[index].collectionIDs.isEmpty {
                libraryItems[index].tagIDs.formUnion(migrated)
                libraryItems[index].collectionIDs.removeAll()
                changed = true
            }
        }
        if var draft = libraryDraft, !draft.collectionIDs.isEmpty {
            draft.tagIDs.formUnion(draft.collectionIDs.compactMap { collectionToTag[$0] })
            draft.collectionIDs.removeAll()
            libraryDraft = draft
            changed = true
        }
        if !collections.isEmpty {
            collections.removeAll()
            changed = true
        }
        if schemaVersion != 3 {
            schemaVersion = 3
            changed = true
        }
        return changed
    }
}

enum LockDelay: String, Codable, CaseIterable, Identifiable {
    case immediately
    case oneMinute
    case fiveMinutes
    var id: String { rawValue }
    var title: String {
        let key = switch self {
        case .immediately: "Immediately"
        case .oneMinute: "After 1 Minute"
        case .fiveMinutes: "After 5 Minutes"
        }
        return key.gentleLocalized
    }
    var seconds: TimeInterval {
        switch self {
        case .immediately: 0
        case .oneMinute: 60
        case .fiveMinutes: 300
        }
    }
}

struct AppPreferences: Codable, Equatable {
    var onboardingComplete = false
    var appLockEnabled = true
    var lockDelay: LockDelay = .immediately
    var showJournalPreviews = true
    var showLibraryPreviews = true
    var showVideoThumbnails = true
    var showGuidedTemplates = true
    var trustedContact: TrustedContact?
    var requireAuthenticationForDeletion: Bool?
    var languageOverride: AppLanguage?
    var showLibraryIntroduction: Bool?
    var showMealReflectionPreviews: Bool? = true
    var mealReflectionsEnabled: Bool?
    var showMealReflectionIntroduction: Bool?
    var previewDefaultsVersion: Int?
}

struct TrustedContact: Codable, Equatable {
    var name: String
    var phoneNumber: String
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, notes, images, videos, audio, kept
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All".gentleLocalized
        case .notes: "Notes".gentleLocalized
        case .images: "Images".gentleLocalized
        case .videos: "Videos".gentleLocalized
        case .audio: "Audio".gentleLocalized
        case .kept: "Kept".gentleLocalized
        }
    }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .notes: "doc"
        case .images: "photo"
        case .videos: "video"
        case .audio: "waveform"
        case .kept: "bookmark"
        }
    }
}
