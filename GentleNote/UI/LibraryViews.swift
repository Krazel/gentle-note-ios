import AVFoundation
import SwiftUI

struct LibraryRootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var filter: LibraryFilter = .all
    @State private var query = ""
    @State private var addChoice: LibraryItemKind?
    @State private var showAdd = false
    @State private var showCollections = false
    @State private var showTags = false

    private var items: [LibraryItem] {
        model.vault.libraryItems
            .filter {
                switch filter {
                case .all: true
                case .notes: $0.kind == .note
                case .videos: $0.kind == .video
                case .audio: $0.kind == .audio
                case .kept: $0.isKept
                }
            }
            .filter { item in
                guard !query.isEmpty else { return true }
                let collectionNames = model.vault.collections.filter { item.collectionIDs.contains($0.id) }.map(\.name)
                let tagNames = model.vault.tags.filter { item.tagIDs.contains($0.id) }.map(\.name)
                return ([item.displayTitle, item.body] + collectionNames + tagNames)
                    .joined(separator: " ").localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Text("Library").font(.system(.largeTitle, design: .serif))
                    Spacer()
                    Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
                        .buttonStyle(.bordered).tint(QuietLinen.forest)
                }.padding(.horizontal, 20).padding(.top, 12)

                if model.vault.libraryItems.isEmpty {
                    Spacer()
                    BotanicalSprig()
                    Text("Keep private notes, videos,\nand audio to return to\nwhen you choose.")
                        .multilineTextAlignment(.center)
                    addButtons
                    Text("Nothing here yet.").font(.footnote).foregroundStyle(QuietLinen.muted)
                    Spacer()
                } else {
                    TextField("Search your library", text: $query)
                        .textFieldStyle(.roundedBorder).padding(.horizontal, 20)
                        .accessibilityHint("Searches notes, titles, collections, and tags on this iPhone")
                    Picker("Library filter", selection: $filter) {
                        ForEach(LibraryFilter.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented).padding(.horizontal, 20)
                    if !model.preferences.showLibraryPreviews {
                        Label("Previews are hidden.", systemImage: "lock.fill")
                            .font(.footnote).foregroundStyle(QuietLinen.muted)
                    }
                    List(items) { item in
                        NavigationLink(value: item) { LibraryRow(item: item) }
                            .listRowBackground(QuietLinen.paperRaised.opacity(0.75))
                    }
                    .scrollContentBackground(.hidden)
                    HStack {
                        Button("Collections") { showCollections = true }
                        Spacer(); Button("Tags") { showTags = true }
                    }.padding(.horizontal, 28).padding(.bottom, 8)
                }
            }
            .linenScreen()
            .navigationDestination(for: LibraryItem.self) { LibraryDetailView(itemID: $0.id) }
        }
        .confirmationDialog("Add to your private library", isPresented: $showAdd) {
            Button("New Note") { addChoice = .note }
            Button("Record Video") { addChoice = .video }
            Button("Record Audio") { addChoice = .audio }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $addChoice) { choice in
            switch choice {
            case .note: NavigationStack { NoteComposerView() }
            case .video: NavigationStack { VideoPermissionPrimer() }
            case .audio: NavigationStack { AudioPermissionPrimer() }
            }
        }
        .sheet(isPresented: $showCollections) { NavigationStack { CollectionsView() } }
        .sheet(isPresented: $showTags) { NavigationStack { TagsView() } }
    }

    private var addButtons: some View {
        VStack(spacing: 10) {
            Button { addChoice = .note } label: { Label("New Note", systemImage: "leaf") }
                .buttonStyle(SecondaryButtonStyle())
            Button { addChoice = .video } label: { Label("Record Video", systemImage: "video.fill") }
                .buttonStyle(SecondaryButtonStyle())
            Button { addChoice = .audio } label: { Label("Record Audio", systemImage: "mic.fill") }
                .buttonStyle(SecondaryButtonStyle())
        }.frame(maxWidth: 430).padding(.horizontal, 24)
    }
}

struct LibraryRow: View {
    @EnvironmentObject private var model: AppModel
    let item: LibraryItem
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.icon).foregroundStyle(QuietLinen.forest).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle).font(.system(.body, design: .serif))
                Text(item.createdAt.gentleDate).font(.caption).foregroundStyle(QuietLinen.muted)
                if model.preferences.showLibraryPreviews, item.kind == .note {
                    Text(item.body).lineLimit(2).font(.caption).foregroundStyle(QuietLinen.muted)
                }
            }
            Spacer()
            if item.isKept { Image(systemName: "bookmark.fill").accessibilityLabel("Kept") }
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayTitle), \(item.kind.title), \(item.createdAt.gentleDate)\(item.isKept ? ", Kept" : "")")
    }
}

struct NoteComposerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var existingID: UUID?
    @State private var title = ""
    @State private var noteText = ""
    @State private var kept = false
    @State private var collectionIDs: Set<UUID> = []
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("New Note").font(.system(.title2, design: .serif))
                TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                LinenTextEditor(prompt: "Write a note to return to later…", text: $noteText, minHeight: 330)
                HStack {
                    Toggle(isOn: $kept) { Label("Keep", systemImage: kept ? "bookmark.fill" : "bookmark") }
                    Button { organize = true } label: { Label("Organize", systemImage: "folder") }
                        .buttonStyle(.bordered).tint(QuietLinen.forest)
                }
                Button(existingID == nil ? "Save Note" : "Save Changes") { save() }
                    .buttonStyle(PrimaryButtonStyle())
                Label("Stored in your private library.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 700)
        }
        .linenScreen().toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onAppear { load() }
        .onChange(of: title) { _, _ in saveDraft() }
        .onChange(of: noteText) { _, _ in saveDraft() }
        .onChange(of: kept) { _, _ in saveDraft() }
        .onChange(of: collectionIDs) { _, _ in saveDraft() }
        .onChange(of: tagIDs) { _, _ in saveDraft() }
        .sheet(isPresented: $organize) {
            OrganizeView(collectionIDs: $collectionIDs, tagIDs: $tagIDs)
                .environmentObject(model)
        }
    }

    private func load() {
        if let item = existingID.flatMap({ id in model.vault.libraryItems.first { $0.id == id } }) {
            title = item.title; noteText = item.body; kept = item.isKept
            collectionIDs = item.collectionIDs; tagIDs = item.tagIDs
        } else if let draft = model.vault.libraryDraft {
            title = draft.title; noteText = draft.body; kept = draft.isKept
            collectionIDs = draft.collectionIDs; tagIDs = draft.tagIDs
        }
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var item = existingID.flatMap { id in model.vault.libraryItems.first { $0.id == id } }
            ?? LibraryItem(kind: .note)
        item.title = title; item.body = noteText; item.isKept = kept
        item.collectionIDs = collectionIDs; item.tagIDs = tagIDs; item.updatedAt = Date()
        try? model.saveLibraryItem(item); dismiss()
    }

    private func saveDraft() {
        guard existingID == nil,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        model.saveLibraryDraft(LibraryDraft(title: title, body: noteText, isKept: kept,
                                            collectionIDs: collectionIDs, tagIDs: tagIDs,
                                            savedAt: Date()))
    }
}

struct OrganizeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Binding var collectionIDs: Set<UUID>
    @Binding var tagIDs: Set<UUID>
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Collections") {
                    if model.vault.collections.isEmpty { Text("No collections yet").foregroundStyle(QuietLinen.muted) }
                    ForEach(model.vault.collections) { collection in
                        Button { toggle(collection.id, binding: $collectionIDs) } label: {
                            HStack { Text(collection.name); Spacer(); if collectionIDs.contains(collection.id) { Image(systemName: "checkmark.circle.fill") } }
                        }.buttonStyle(.plain)
                    }
                }
                Section("Tags") {
                    ForEach(model.vault.tags) { tag in
                        Button { toggle(tag.id, binding: $tagIDs) } label: {
                            HStack { Text(tag.name); Spacer(); if tagIDs.contains(tag.id) { Image(systemName: "checkmark.circle.fill") } }
                        }.buttonStyle(.plain)
                    }
                    HStack {
                        TextField("Add a tag", text: $newTag)
                        Button("Add") {
                            guard !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            if let tag = try? model.addTag(named: newTag) { tagIDs.insert(tag.id) }
                            newTag = ""
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).linenScreen().navigationTitle("Organize")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func toggle(_ id: UUID, binding: Binding<Set<UUID>>) {
        var changed = binding.wrappedValue
        if changed.contains(id) { changed.remove(id) } else { changed.insert(id) }
        binding.wrappedValue = changed
    }
}

struct VideoPermissionPrimer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var continueToRecorder = false
    @State private var denied = false
    var body: some View {
        PermissionPrimer(title: "Record a private video",
                         message: "Gentle Note needs camera and microphone access only while you record. Videos stay inside the app unless you export them.",
                         rows: [("Camera", "video.fill", MediaPermissions.camera()),
                                ("Microphone", "mic.fill", MediaPermissions.microphone())],
                         footer: "Nothing is saved to Photos.") {
            Task {
                if await MediaPermissions.requestCameraAndMicrophone() { continueToRecorder = true }
                else { denied = true }
            }
        }
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .navigationDestination(isPresented: $continueToRecorder) { VideoRecorderView() }
        .alert("Camera and microphone are off", isPresented: $denied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record a video without access. You can change this in iPhone Settings.") }
    }
}

struct AudioPermissionPrimer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var continueToRecorder = false
    @State private var denied = false
    var body: some View {
        PermissionPrimer(title: "Record a private audio note",
                         message: "Gentle Note needs microphone access only while you record. Audio stays inside the app unless you export it.",
                         rows: [("Microphone", "mic.fill", MediaPermissions.microphone())],
                         footer: "Nothing is saved to Photos.") {
            Task {
                if await MediaPermissions.requestMicrophone() { continueToRecorder = true }
                else { denied = true }
            }
        }
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .navigationDestination(isPresented: $continueToRecorder) { AudioRecorderView() }
        .alert("Microphone is off", isPresented: $denied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record audio without access. You can change this in iPhone Settings.") }
    }
}

struct PermissionPrimer: View {
    let title: String
    let message: String
    let rows: [(String, String, MediaPermissionState)]
    let footer: String
    let action: () -> Void
    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 20) {
                Spacer(); BotanicalSprig(); Text(title).editorialTitle()
                Text(message).multilineTextAlignment(.center)
                LinenCard { VStack { ForEach(Array(rows.enumerated()), id: \.offset) { _, row in PermissionStatusRow(title: row.0, icon: row.1, state: row.2) } } }
                Button("Continue", action: action).buttonStyle(PrimaryButtonStyle())
                Label(footer, systemImage: "lock").font(.footnote).foregroundStyle(QuietLinen.muted)
                Spacer()
            }.padding(24).frame(maxWidth: 580)
        }
    }
}

struct VideoRecorderView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VideoRecorder()
    @State private var title = ""
    @State private var kept = false
    @State private var collectionIDs: Set<UUID> = []
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(recorder.finishedURL == nil ? (recorder.isRecording ? "Recording" : "Record Video") : "Review Video")
                    .font(.system(.title2, design: .serif))
                CameraPreview(session: recorder.session)
                    .frame(maxWidth: .infinity).aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(alignment: .top) {
                        if recorder.isRecording {
                            Label(recorder.elapsed.clockString, systemImage: "record.circle.fill")
                                .padding(8).background(.thinMaterial, in: Capsule()).padding(10)
                        }
                    }
                    .accessibilityLabel("Camera preview")
                if recorder.finishedURL == nil {
                    HStack {
                        Button { recorder.flipCamera() } label: { Label("Flip Camera", systemImage: "arrow.triangle.2.circlepath.camera") }
                            .disabled(recorder.isRecording)
                        Spacer()
                        Button {
                            recorder.isRecording ? recorder.stop() : recorder.start()
                        } label: {
                            Image(systemName: recorder.isRecording ? "stop.fill" : "record.circle")
                                .font(.system(size: 62)).foregroundStyle(QuietLinen.clay)
                        }
                        .disabled(!recorder.isReady && !recorder.isRecording)
                        .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")
                        Spacer()
                        Label("Mic On", systemImage: "mic.fill")
                    }
                } else {
                    TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                        Button { organize = true } label: { Label("Organize", systemImage: "folder") }.buttonStyle(.bordered)
                    }
                    Button("Save Video") { saveVideo() }.buttonStyle(PrimaryButtonStyle())
                    Button("Retake") { discardRecording(); recorder.start() }.buttonStyle(SecondaryButtonStyle())
                    Button("Delete Recording", role: .destructive) { discardRecording() }.foregroundStyle(QuietLinen.danger)
                }
                Label("Your video stays in this app.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 720)
        }
        .linenScreen().navigationBarBackButtonHidden(recorder.isRecording)
        .onAppear { recorder.configure() }
        .onDisappear { recorder.stopSession() }
        .onChange(of: recorder.errorMessage) { _, value in error = value }
        .sheet(isPresented: $organize) { OrganizeView(collectionIDs: $collectionIDs, tagIDs: $tagIDs).environmentObject(model) }
        .alert("Recording interrupted", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Review Recording") { error = nil }
            Button("Delete Partial Recording", role: .destructive) { discardRecording(); error = nil }
        } message: { Text(error ?? "Your saved items are unchanged.") }
    }

    private func saveVideo() {
        guard let url = recorder.finishedURL else { return }
        do {
            let seconds = AVURLAsset(url: url).duration.seconds
            let filename = try model.store.importRecording(from: url, extension: "mov")
            var item = LibraryItem(kind: .video)
            item.title = title; item.isKept = kept; item.collectionIDs = collectionIDs; item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename; item.mediaFileExtension = "mov"
            item.duration = seconds.isFinite ? seconds : recorder.elapsed
            try model.saveLibraryItem(item)
            dismiss()
        } catch { error = error.localizedDescription }
    }

    private func discardRecording() {
        if let url = recorder.finishedURL { try? FileManager.default.removeItem(at: url) }
        recorder.finishedURL = nil
    }
}

struct AudioRecorderView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorder()
    @State private var title = ""
    @State private var kept = false
    @State private var collectionIDs: Set<UUID> = []
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Record Audio").font(.system(.title2, design: .serif))
                DecorativeWaveform(level: recorder.level).frame(height: 110)
                Label(recorder.elapsed.clockString, systemImage: recorder.isRecording ? "record.circle.fill" : "mic.fill")
                    .font(.title2)
                if recorder.finishedURL == nil {
                    HStack(spacing: 26) {
                        if recorder.isRecording {
                            Button { recorder.pauseOrResume() } label: {
                                Label(recorder.isPaused ? "Resume" : "Pause", systemImage: recorder.isPaused ? "play.fill" : "pause.fill")
                            }.buttonStyle(.bordered).tint(QuietLinen.forest)
                        }
                        Button {
                            recorder.isRecording ? recorder.stop() : recorder.start()
                        } label: {
                            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                                .font(.system(size: 66)).foregroundStyle(QuietLinen.clay)
                        }.accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")
                    }
                } else {
                    TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                        Button { organize = true } label: { Label("Organize", systemImage: "folder") }.buttonStyle(.bordered)
                    }
                    Button("Save Audio") { saveAudio() }.buttonStyle(PrimaryButtonStyle())
                    Button("Retake") { discard(); recorder.start() }.buttonStyle(SecondaryButtonStyle())
                    Button("Delete Recording", role: .destructive) { discard() }.foregroundStyle(QuietLinen.danger)
                }
                Label("Stored only in this app.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 680)
        }
        .linenScreen().sheet(isPresented: $organize) { OrganizeView(collectionIDs: $collectionIDs, tagIDs: $tagIDs).environmentObject(model) }
        .onChange(of: recorder.errorMessage) { _, value in error = value }
        .alert("Audio couldn’t be recorded", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Your saved items are unchanged.") }
    }

    private func saveAudio() {
        guard let url = recorder.finishedURL else { return }
        do {
            let filename = try model.store.importRecording(from: url, extension: "m4a")
            var item = LibraryItem(kind: .audio)
            item.title = title; item.isKept = kept; item.collectionIDs = collectionIDs; item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename; item.mediaFileExtension = "m4a"; item.duration = recorder.elapsed
            try model.saveLibraryItem(item); dismiss()
        } catch { error = error.localizedDescription }
    }

    private func discard() {
        if let url = recorder.finishedURL { try? FileManager.default.removeItem(at: url) }
        recorder.finishedURL = nil
    }
}

struct LibraryDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let itemID: UUID
    @State private var readableURL: URL?
    @State private var edit = false
    @State private var confirmDelete = false
    @State private var exportURL: URL?
    @State private var share = false
    @State private var error: String?

    private var item: LibraryItem? { model.vault.libraryItems.first { $0.id == itemID } }

    var body: some View {
        ScrollView {
            if let item {
                VStack(spacing: 15) {
                    Text(item.displayTitle).editorialTitle()
                    Text(item.createdAt.formatted(date: .long, time: .shortened)).font(.caption).foregroundStyle(QuietLinen.muted)
                    if item.kind == .note {
                        LinenCard { Text(item.body).frame(maxWidth: .infinity, alignment: .leading) }
                    } else if let readableURL {
                        MediaPlayerView(url: readableURL, kind: item.kind)
                        if let duration = item.duration { Text(duration.clockString).font(.caption).foregroundStyle(QuietLinen.muted) }
                    } else {
                        ProgressView("Opening private recording…")
                    }
                    metadata(for: item)
                    Button { toggleKept(item) } label: { Label(item.isKept ? "Remove from Kept" : "Keep", systemImage: "bookmark") }
                        .buttonStyle(SecondaryButtonStyle())
                    if item.kind == .note { Button("Edit Details") { edit = true }.buttonStyle(SecondaryButtonStyle()) }
                    Button("Export \(item.kind.title)") { export(item) }.buttonStyle(SecondaryButtonStyle())
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete \(item.kind.title)", systemImage: "trash") }
                        .buttonStyle(SecondaryButtonStyle()).foregroundStyle(QuietLinen.danger)
                    Label("Stored on this iPhone.", systemImage: "iphone")
                        .font(.footnote).foregroundStyle(QuietLinen.muted)
                }.padding(20).frame(maxWidth: 720)
            }
        }
        .linenScreen().task { openMediaIfNeeded() }
        .onDisappear { try? model.store.clearTemporaryFiles() }
        .sheet(isPresented: $edit) { if item?.kind == .note { NavigationStack { NoteComposerView(existingID: itemID) } } }
        .sheet(isPresented: $share) { if let exportURL { ActivitySheet(items: [exportURL]) { try? model.store.clearTemporaryFiles() } } }
        .confirmationDialog("Delete this \(item?.kind.title.lowercased() ?? "item")?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete \(item?.kind.title ?? "Item")", role: .destructive) {
                Task {
                    guard await model.authenticateSensitiveAction(reason: "Confirm deletion of this private library item.") else { return }
                    do { try model.deleteLibraryItem(itemID); dismiss() } catch { self.error = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes it from this iPhone. It cannot be undone.") }
        .alert("This item couldn’t be opened", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Try again.") }
    }

    private func metadata(for item: LibraryItem) -> some View {
        let collections = model.vault.collections.filter { item.collectionIDs.contains($0.id) }
        let tags = model.vault.tags.filter { item.tagIDs.contains($0.id) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(collections) { Text($0.name).padding(.horizontal, 10).padding(.vertical, 6).background(QuietLinen.sage.opacity(0.28), in: Capsule()) }
                ForEach(tags) { Text($0.name).padding(.horizontal, 10).padding(.vertical, 6).background(QuietLinen.clay.opacity(0.2), in: Capsule()) }
            }
        }
    }

    private func openMediaIfNeeded() {
        guard let item, item.kind != .note,
              let filename = item.encryptedMediaFilename, let ext = item.mediaFileExtension else { return }
        do { readableURL = try model.store.readableMediaURL(filename: filename, extension: ext) }
        catch { self.error = error.localizedDescription }
    }

    private func toggleKept(_ item: LibraryItem) {
        var changed = item; changed.isKept.toggle(); changed.updatedAt = Date(); try? model.saveLibraryItem(changed)
    }

    private func export(_ item: LibraryItem) {
        Task {
            guard await model.authenticateSensitiveAction(reason: "Confirm export of this private \(item.kind.title.lowercased()).") else { return }
            do {
                exportURL = try ExportService(store: model.store).libraryItem(item, format: item.kind == .note ? .pdf : .originalMedia)
                share = true
            } catch { self.error = error.localizedDescription }
        }
    }
}

struct CollectionsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var editing: LibraryCollection?
    var body: some View {
        List {
            ForEach(model.vault.collections) { collection in
                Button { editing = collection } label: {
                    LinenCard { HStack { Image(systemName: collection.symbol.rawValue); Text(collection.name).font(.system(.title3, design: .serif)); Spacer(); Image(systemName: "chevron.right") } }
                }.buttonStyle(.plain)
            }
            Button { editing = LibraryCollection(name: "") } label: { Label("New Collection", systemImage: "plus") }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Collections")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .sheet(item: $editing) { collection in NavigationStack { EditCollectionView(collection: collection) } }
    }
}

struct EditCollectionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var collection: LibraryCollection
    @State private var confirmDelete = false
    var body: some View {
        Form {
            Section("Collection name") { TextField("Things to Remember", text: $collection.name) }
            Section("Symbol") {
                Picker("Symbol", selection: $collection.symbol) { ForEach(CollectionSymbol.allCases) { Label($0.rawValue, systemImage: $0.rawValue).tag($0) } }
            }
            Section("Color") { Picker("Color", selection: $collection.color) { ForEach(CollectionColor.allCases) { Text($0.rawValue.capitalized).tag($0) } } }
            Button("Save Collection") { guard !collection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }; try? model.addCollection(collection); dismiss() }
            if model.vault.collections.contains(where: { $0.id == collection.id }) {
                Button("Delete Collection", role: .destructive) { confirmDelete = true }
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Edit Collection")
        .confirmationDialog("Delete this collection?", isPresented: $confirmDelete) {
            Button("Delete Collection", role: .destructive) { try? model.deleteCollection(collection.id); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Deleting a collection does not delete the items inside it.") }
    }
}

struct TagsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    @State private var search = ""
    private var visibleTags: [LibraryTag] {
        search.isEmpty ? model.vault.tags : model.vault.tags.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        List {
            Section {
                HStack { TextField("New tag", text: $newTag); Button("Add") { if !newTag.isEmpty { _ = try? model.addTag(named: newTag); newTag = "" } } }
            }
            Section("Tags") {
                ForEach(visibleTags) { tag in
                    HStack { Image(systemName: "tag"); Text(tag.name); Spacer() }
                        .swipeActions { Button("Delete", role: .destructive) { try? model.deleteTag(tag.id) } }
                }
            } footer: { Text("Deleting a tag does not delete the items that use it.") }
        }
        .searchable(text: $search, prompt: "Search tags")
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Tags")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
