import Foundation

extension String {
    var gentleLocalized: String {
        NSLocalizedString(self, tableName: nil, bundle: .main, value: self, comment: "")
    }

    func gentleLocalizedFormat(_ arguments: CVarArg...) -> String {
        String(format: gentleLocalized, locale: Locale.current, arguments: arguments)
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
        case .noticeSomethingSmall: "sprout"
        }
    }

    var intro: String {
        let key = switch self {
        case .blank: "Write whatever feels useful right now."
        case .gentleCheckIn: "Answer any question, in any order. Leave anything blank."
        case .balancedThought: "A gentle, non-scored reflection. Every prompt is optional."
        case .selfCompassionPause: "Make room for difficulty without needing to fix it."
        case .valuesCompass: "Notice what matters without turning it into a target."
        case .presentMoment: "Notice the present without needing to change it."
        case .prepareToTalk: "Gather words for yourself, someone you trust, or your care team."
        case .noticeSomethingSmall: "This is not a score or achievement."
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
    case note, video, audio
    var id: String { rawValue }
    var title: String {
        switch self {
        case .note: "Note".gentleLocalized
        case .video: "Video".gentleLocalized
        case .audio: "Audio".gentleLocalized
        }
    }
    var icon: String {
        switch self {
        case .note: "doc"
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
        case .video: "Untitled Video".gentleLocalized
        case .audio: "Untitled Audio".gentleLocalized
        }
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
    var defaultKind: DefaultCollectionKind?

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
    var schemaVersion = 1
    var journalEntries: [JournalEntry] = []
    var libraryItems: [LibraryItem] = []
    var collections: [LibraryCollection] = LibraryCollection.defaults
    var tags: [LibraryTag] = []
    var journalDraft: JournalDraft?
    var libraryDraft: LibraryDraft?
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
    var showJournalPreviews = false
    var showLibraryPreviews = false
    var showVideoThumbnails = false
    var showGuidedTemplates = true
    var trustedContact: TrustedContact?
    var requireAuthenticationForDeletion: Bool?
}

struct TrustedContact: Codable, Equatable {
    var name: String
    var phoneNumber: String
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, notes, videos, audio, kept
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All".gentleLocalized
        case .notes: "Notes".gentleLocalized
        case .videos: "Videos".gentleLocalized
        case .audio: "Audio".gentleLocalized
        case .kept: "Kept".gentleLocalized
        }
    }
}
