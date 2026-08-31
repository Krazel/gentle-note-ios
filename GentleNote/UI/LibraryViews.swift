import AVFoundation
import CoreTransferable
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct LibraryRootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var filter: LibraryFilter = .all
    @State private var query = ""
    @State private var addChoice: LibraryItemKind?
    @State private var showAdd = false
    @State private var showTags = false
    @State private var selectedTagID: UUID?

    private var selectedTag: LibraryTag? {
        model.vault.tags.first { $0.id == selectedTagID }
    }

    private var items: [LibraryItem] {
        model.vault.libraryItems
            .filter { $0.matches(filter) }
            .filter { $0.hasTag(selectedTag?.id) }
            .filter { item in
                guard !query.isEmpty else { return true }
                let tagNames = model.vault.tags.filter { item.tagIDs.contains($0.id) }.map(\.displayName)
                return ([item.displayTitle, item.body] + tagNames)
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

                if model.showsLibraryIntroduction {
                    LinenCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "books.vertical")
                                .foregroundStyle(QuietLinen.forest)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Keep what you may want to remember").font(.headline)
                                Text("Save notes, images, and private recordings you may want to return to—words, reminders, or things that feel clear now but may become harder to remember later.")
                                    .font(.footnote).foregroundStyle(QuietLinen.muted)
                            }
                            Spacer(minLength: 4)
                            Button {
                                model.setLibraryIntroductionVisible(false)
                            } label: {
                                Image(systemName: "xmark")
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Hide Library introduction")
                            .accessibilityHint("You can show it again in Settings")
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if model.vault.libraryItems.isEmpty {
                    Spacer()
                    BotanicalSprig()
                    addButtons
                    Text("Nothing here yet.").font(.footnote).foregroundStyle(QuietLinen.muted)
                    Spacer()
                } else {
                    TextField("Search your library", text: $query)
                        .textFieldStyle(.roundedBorder).padding(.horizontal, 20)
                        .accessibilityHint("Searches notes, titles, and tags on this iPhone")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LibraryFilter.allCases) { option in
                                Button {
                                    filter = option
                                } label: {
                                    Label(option.title, systemImage: option.icon)
                                        .font(.footnote.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .frame(minHeight: 38)
                                        .background(filter == option ? QuietLinen.forest : QuietLinen.paperRaised,
                                                    in: Capsule())
                                        .foregroundStyle(filter == option ? Color.white : QuietLinen.ink)
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(filter == option ? .isSelected : [])
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    if let selectedTag {
                        HStack(spacing: 8) {
                            Label(selectedTag.displayName, systemImage: "tag")
                                .font(.footnote.weight(.medium))
                            Button {
                                selectedTagID = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear tag filter")
                        }
                        .padding(.horizontal, 12).frame(minHeight: 36)
                        .background(QuietLinen.sage.opacity(0.3), in: Capsule())
                    }
                    if !model.preferences.showLibraryPreviews {
                        Label("Previews are hidden.", systemImage: "lock.fill")
                            .font(.footnote).foregroundStyle(QuietLinen.muted)
                    }
                    if items.isEmpty {
                        Spacer()
                        Text((selectedTag == nil ? "No items match this filter." : "No items with this tag.").gentleLocalized)
                            .font(.footnote).foregroundStyle(QuietLinen.muted)
                        Spacer()
                    } else {
                        List(items) { item in
                            NavigationLink(value: item) { LibraryRow(item: item) }
                                .listRowBackground(QuietLinen.paperRaised.opacity(0.75))
                        }
                        .scrollContentBackground(.hidden)
                    }
                    Button { showTags = true } label: {
                        Label("Filter and manage tags", systemImage: "tag")
                    }
                    .padding(.bottom, 8)
                }
            }
            .linenScreen()
            .navigationDestination(for: LibraryItem.self) { LibraryDetailView(itemID: $0.id) }
        }
        .confirmationDialog("Add to your private library", isPresented: $showAdd) {
            Button("New Note") { addChoice = .note }
            Button("Add Image") { addChoice = .image }
            Button("Add Video") { addChoice = .video }
            Button("Add Audio") { addChoice = .audio }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $addChoice) { choice in
            switch choice {
            case .note: NavigationStack { NoteComposerView() }
            case .image: NavigationStack { ImageImportView() }
            case .video: NavigationStack { VideoPermissionPrimer() }
            case .audio: NavigationStack { AudioPermissionPrimer() }
            }
        }
        .sheet(isPresented: $showTags) {
            NavigationStack { TagsView(selectedTagID: $selectedTagID) }
        }
    }

    private var addButtons: some View {
        VStack(spacing: 10) {
            Button { addChoice = .note } label: { Label("New Note", systemImage: "leaf") }
                .buttonStyle(SecondaryButtonStyle())
            Button { addChoice = .image } label: { Label("Add Image", systemImage: "photo.fill") }
                .buttonStyle(SecondaryButtonStyle())
            Button { addChoice = .video } label: { Label("Add Video", systemImage: "video.fill") }
                .buttonStyle(SecondaryButtonStyle())
            Button { addChoice = .audio } label: { Label("Add Audio", systemImage: "mic.fill") }
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
        .accessibilityLabel("\(item.displayTitle), \(item.kind.title), \(item.createdAt.gentleDate)\(item.isKept ? ", " + "Kept".gentleLocalized : "")")
    }
}

struct NoteComposerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var existingID: UUID?
    @State private var title = ""
    @State private var noteText = ""
    @State private var kept = false
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
                    Button { organize = true } label: { Label("Tags", systemImage: "tag") }
                        .buttonStyle(.bordered).tint(QuietLinen.forest)
                }
                Button((existingID == nil ? "Save Note" : "Save Changes").gentleLocalized) { save() }
                    .buttonStyle(PrimaryButtonStyle())
                Label("Stored in your private library.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 700)
        }
        .linenScreen().toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onAppear { load() }
        .onChange(of: title) { _ in saveDraft() }
        .onChange(of: noteText) { _ in saveDraft() }
        .onChange(of: kept) { _ in saveDraft() }
        .onChange(of: tagIDs) { _ in saveDraft() }
        .sheet(isPresented: $organize) {
            OrganizeView(tagIDs: $tagIDs)
                .environmentObject(model)
        }
    }

    private func load() {
        if let item = existingID.flatMap({ id in model.vault.libraryItems.first { $0.id == id } }) {
            title = item.title; noteText = item.body; kept = item.isKept
            tagIDs = item.tagIDs
        } else if let draft = model.vault.libraryDraft {
            title = draft.title; noteText = draft.body; kept = draft.isKept
            tagIDs = draft.tagIDs
        }
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var item = existingID.flatMap { id in model.vault.libraryItems.first { $0.id == id } }
            ?? LibraryItem(kind: .note)
        item.title = title; item.body = noteText; item.isKept = kept
        item.tagIDs = tagIDs; item.updatedAt = Date()
        try? model.saveLibraryItem(item); dismiss()
    }

    private func saveDraft() {
        guard existingID == nil,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        model.saveLibraryDraft(LibraryDraft(title: title, body: noteText, isKept: kept,
                                            collectionIDs: [], tagIDs: tagIDs,
                                            savedAt: Date()))
    }
}

struct OrganizeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Binding var tagIDs: Set<UUID>
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Tags") {
                    ForEach(model.vault.tags) { tag in
                        Button { toggle(tag.id, binding: $tagIDs) } label: {
                            HStack { Text(tag.displayName); Spacer(); if tagIDs.contains(tag.id) { Image(systemName: "checkmark.circle.fill") } }
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
            .scrollContentBackground(.hidden).linenScreen().navigationTitle("Tags")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func toggle(_ id: UUID, binding: Binding<Set<UUID>>) {
        var changed = binding.wrappedValue
        if changed.contains(id) { changed.remove(id) } else { changed.insert(id) }
        binding.wrappedValue = changed
    }
}

struct ImageImportView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var fileExtension = "jpg"
    @State private var title = ""
    @State private var kept = false
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false
    @State private var showCamera = false
    @State private var cameraDenied = false
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Add an Image").editorialTitle()
                Text("Take a photo or choose one from your library.")
                    .multilineTextAlignment(.center).foregroundStyle(QuietLinen.muted)

                if isLoading {
                    ProgressView("Opening image…")
                        .frame(minHeight: 220)
                } else if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 460)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("Selected image")
                    TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                        Button { organize = true } label: {
                            Label("Tags", systemImage: "tag")
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Save Image") { saveImage() }.buttonStyle(PrimaryButtonStyle())
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose a Different Image", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button { openCamera() } label: {
                        Label("Take a Different Photo", systemImage: "camera")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    BotanicalSprig()
                    Button { openCamera() } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Label("Gentle Note receives only the image you choose.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            .padding(20).frame(maxWidth: 680)
        }
        .linenScreen()
        .navigationTitle("Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .sheet(isPresented: $organize) {
            OrganizeView(tagIDs: $tagIDs).environmentObject(model)
        }
        .fullScreenCover(isPresented: $showCamera) {
            PhotoCapturePicker { image in
                guard let data = image.jpegData(compressionQuality: 0.9) else {
                    error = "This photo couldn’t be prepared.".gentleLocalized
                    return
                }
                imageData = data
                fileExtension = "jpg"
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhoto) { item in load(item) }
        .alert("This image couldn’t be added", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("Done") { error = nil }
        } message: {
            Text(error ?? "Try another image.".gentleLocalized)
        }
        .alert("Camera is off", isPresented: $cameraDenied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot take a photo without camera access. You can change this in iPhone Settings.") }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "The camera is unavailable.".gentleLocalized
            return
        }
        Task {
            if await MediaPermissions.requestCamera() { showCamera = true }
            else { cameraDenied = true }
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoading = true
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      UIImage(data: data) != nil else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let ext = item.supportedContentTypes
                    .first(where: { $0.conforms(to: .image) })?
                    .preferredFilenameExtension ?? "jpg"
                await MainActor.run {
                    imageData = data
                    fileExtension = ext
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func saveImage() {
        guard let imageData else { return }
        do {
            let source = model.store.temporaryURL
                .appendingPathComponent(UUID().uuidString + "." + fileExtension)
            try imageData.write(to: source, options: .atomic)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                  ofItemAtPath: source.path)
            let filename = try model.store.importMedia(from: source, extension: fileExtension)
            var item = LibraryItem(kind: .image)
            item.title = title
            item.isKept = kept
            item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename
            item.mediaFileExtension = fileExtension
            try model.saveLibraryItem(item)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct VideoPermissionPrimer: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var continueToRecorder = false
    @State private var denied = false
    @State private var selectedVideo: PhotosPickerItem?
    @State private var importedMedia: ImportedMediaFile?
    @State private var showImportedMedia = false
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 20) {
                Spacer(); BotanicalSprig(); Text("Add a Video").editorialTitle()
                Text("Record a new video or choose one from Photos.")
                    .multilineTextAlignment(.center)
                LinenCard {
                    VStack {
                        PermissionStatusRow(title: "Camera", icon: "video.fill", state: MediaPermissions.camera())
                        PermissionStatusRow(title: "Microphone", icon: "mic.fill", state: MediaPermissions.microphone())
                    }
                }
                if isLoading {
                    ProgressView("Opening video…")
                } else {
                    Button { requestRecordingAccess() } label: {
                        Label("Record Video", systemImage: "video.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                Label("Your chosen or recorded video stays inside the app unless you export it.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
                Spacer()
            }
            .padding(24).frame(maxWidth: 580)
        }
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .navigationDestination(isPresented: $continueToRecorder) { VideoRecorderView(onSaved: { dismiss() }) }
        .navigationDestination(isPresented: $showImportedMedia) {
            if let importedMedia {
                ImportedMediaComposerView(kind: .video, media: importedMedia, onSaved: { dismiss() })
            }
        }
        .onChange(of: selectedVideo) { loadVideo($0) }
        .alert("Camera and microphone are off", isPresented: $denied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record a video without access. You can change this in iPhone Settings.") }
        .alert("This video couldn’t be added", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Try another video.".gentleLocalized) }
    }

    private func requestRecordingAccess() {
        Task {
            if await MediaPermissions.requestCameraAndMicrophone() { continueToRecorder = true }
            else { denied = true }
        }
    }

    private func loadVideo(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoading = true
        Task {
            do {
                let picked = try await item.loadTransferable(type: PickedVideoFile.self)
                guard let picked else { throw CocoaError(.fileReadUnknown) }
                let ext = picked.url.pathExtension.isEmpty ? "mov" : picked.url.pathExtension
                let protectedCopy = model.store.temporaryURL
                    .appendingPathComponent(UUID().uuidString + "." + ext)
                do {
                    try FileManager.default.copyItem(at: picked.url, to: protectedCopy)
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                          ofItemAtPath: protectedCopy.path)
                } catch {
                    try? FileManager.default.removeItem(at: picked.url)
                    throw error
                }
                try? FileManager.default.removeItem(at: picked.url)
                let asset = AVURLAsset(url: protectedCopy)
                let seconds = asset.duration.seconds
                await MainActor.run {
                    importedMedia = ImportedMediaFile(url: protectedCopy, fileExtension: ext,
                                                      duration: seconds.isFinite ? seconds : nil)
                    selectedVideo = nil
                    isLoading = false
                    showImportedMedia = true
                }
            } catch {
                await MainActor.run {
                    selectedVideo = nil
                    isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

struct AudioPermissionPrimer: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var continueToRecorder = false
    @State private var denied = false
    @State private var showFileImporter = false
    @State private var importedMedia: ImportedMediaFile?
    @State private var showImportedMedia = false
    @State private var error: String?

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 20) {
                Spacer(); BotanicalSprig(); Text("Add Audio").editorialTitle()
                Text("Record new audio or choose an audio file already on your iPhone.")
                    .multilineTextAlignment(.center)
                LinenCard {
                    PermissionStatusRow(title: "Microphone", icon: "mic.fill", state: MediaPermissions.microphone())
                }
                Button { requestRecordingAccess() } label: {
                    Label("Record Audio", systemImage: "mic.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button { showFileImporter = true } label: {
                    Label("Choose Audio File", systemImage: "folder")
                }
                .buttonStyle(SecondaryButtonStyle())
                Label("Your chosen or recorded audio stays inside the app unless you export it.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
                Spacer()
            }
            .padding(24).frame(maxWidth: 580)
        }
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .navigationDestination(isPresented: $continueToRecorder) { AudioRecorderView(onSaved: { dismiss() }) }
        .navigationDestination(isPresented: $showImportedMedia) {
            if let importedMedia {
                ImportedMediaComposerView(kind: .audio, media: importedMedia, onSaved: { dismiss() })
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.audio]) { result in
            loadAudio(result)
        }
        .alert("Microphone is off", isPresented: $denied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record audio without access. You can change this in iPhone Settings.") }
        .alert("This audio couldn’t be added", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Try another audio file.".gentleLocalized) }
    }

    private func requestRecordingAccess() {
        Task {
            if await MediaPermissions.requestMicrophone() { continueToRecorder = true }
            else { denied = true }
        }
    }

    private func loadAudio(_ result: Result<URL, Error>) {
        do {
            let selectedURL = try result.get()
            let hasAccess = selectedURL.startAccessingSecurityScopedResource()
            defer { if hasAccess { selectedURL.stopAccessingSecurityScopedResource() } }
            let ext = selectedURL.pathExtension.isEmpty ? "m4a" : selectedURL.pathExtension
            let copy = model.store.temporaryURL.appendingPathComponent(UUID().uuidString + "." + ext)
            try FileManager.default.copyItem(at: selectedURL, to: copy)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: copy.path)
            let seconds = AVURLAsset(url: copy).duration.seconds
            importedMedia = ImportedMediaFile(url: copy, fileExtension: ext,
                                              duration: seconds.isFinite ? seconds : nil)
            showImportedMedia = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PermissionPrimer: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let rows: [(LocalizedStringKey, String, MediaPermissionState)]
    let footer: LocalizedStringKey
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

struct ImportedMediaFile: Identifiable {
    let id = UUID()
    let url: URL
    let fileExtension: String
    let duration: TimeInterval?
}

struct PickedVideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "." + ext)
            try FileManager.default.copyItem(at: received.file, to: copy)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                  ofItemAtPath: copy.path)
            return PickedVideoFile(url: copy)
        }
    }
}

struct ImportedMediaComposerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let kind: LibraryItemKind
    let media: ImportedMediaFile
    var onSaved: (() -> Void)?
    @State private var title = ""
    @State private var kept = false
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false
    @State private var didSave = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text((kind == .video ? "Add Video" : "Add Audio").gentleLocalized)
                    .font(.system(.title2, design: .serif))
                MediaPlayerView(url: media.url, kind: kind)
                if let duration = media.duration {
                    Text(duration.clockString).font(.caption).foregroundStyle(QuietLinen.muted)
                }
                TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                HStack {
                    Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                    Button { organize = true } label: { Label("Tags", systemImage: "tag") }
                        .buttonStyle(.bordered)
                }
                Button { save() } label: {
                    Text((kind == .video ? "Save Video" : "Save Audio").gentleLocalized)
                }
                .buttonStyle(PrimaryButtonStyle())
                Label("Stored in your private library.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            .padding(20).frame(maxWidth: 700)
        }
        .linenScreen()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $organize) { OrganizeView(tagIDs: $tagIDs).environmentObject(model) }
        .onDisappear {
            if !didSave { try? FileManager.default.removeItem(at: media.url) }
        }
        .alert("This item couldn’t be saved", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Keep Editing") { error = nil }
        } message: { Text(error ?? "Your saved items are unchanged.".gentleLocalized) }
    }

    private func save() {
        do {
            let filename = try model.store.importMedia(from: media.url, extension: media.fileExtension)
            var item = LibraryItem(kind: kind)
            item.title = title
            item.isKept = kept
            item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename
            item.mediaFileExtension = media.fileExtension
            item.duration = media.duration
            try model.saveLibraryItem(item)
            didSave = true
            if let onSaved { onSaved() } else { dismiss() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct VideoRecorderView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VideoRecorder()
    var onSaved: (() -> Void)?
    @State private var title = ""
    @State private var kept = false
    @State private var tagIDs: Set<UUID> = []
    @State private var organize = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text((recorder.finishedURL == nil ? (recorder.isRecording ? "Recording" : "Record Video") : "Review Video").gentleLocalized)
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
                        .accessibilityLabel((recorder.isRecording ? "Stop recording" : "Start recording").gentleLocalized)
                        Spacer()
                        Label("Mic On", systemImage: "mic.fill")
                    }
                } else {
                    TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                        Button { organize = true } label: { Label("Tags", systemImage: "tag") }.buttonStyle(.bordered)
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
        .onChange(of: recorder.errorMessage) { value in error = value }
        .sheet(isPresented: $organize) { OrganizeView(tagIDs: $tagIDs).environmentObject(model) }
        .alert("Recording interrupted", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Review Recording") { error = nil }
            Button("Delete Partial Recording", role: .destructive) { discardRecording(); error = nil }
        } message: { Text(error ?? "Your saved items are unchanged.".gentleLocalized) }
    }

    private func saveVideo() {
        guard let url = recorder.finishedURL else { return }
        do {
            let seconds = AVURLAsset(url: url).duration.seconds
            let filename = try model.store.importMedia(from: url, extension: "mov")
            var item = LibraryItem(kind: .video)
            item.title = title; item.isKept = kept; item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename; item.mediaFileExtension = "mov"
            item.duration = seconds.isFinite ? seconds : recorder.elapsed
            try model.saveLibraryItem(item)
            if let onSaved { onSaved() } else { dismiss() }
        } catch let caughtError { error = caughtError.localizedDescription }
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
    var onSaved: (() -> Void)?
    @State private var title = ""
    @State private var kept = false
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
                                Label((recorder.isPaused ? "Resume" : "Pause").gentleLocalized, systemImage: recorder.isPaused ? "play.fill" : "pause.fill")
                            }.buttonStyle(.bordered).tint(QuietLinen.forest)
                        }
                        Button {
                            recorder.isRecording ? recorder.stop() : recorder.start()
                        } label: {
                            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                                .font(.system(size: 66)).foregroundStyle(QuietLinen.clay)
                        }.accessibilityLabel((recorder.isRecording ? "Stop recording" : "Start recording").gentleLocalized)
                    }
                } else {
                    TextField("Optional title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Toggle(isOn: $kept) { Label("Keep", systemImage: "bookmark") }
                        Button { organize = true } label: { Label("Tags", systemImage: "tag") }.buttonStyle(.bordered)
                    }
                    Button("Save Audio") { saveAudio() }.buttonStyle(PrimaryButtonStyle())
                    Button("Retake") { discard(); recorder.start() }.buttonStyle(SecondaryButtonStyle())
                    Button("Delete Recording", role: .destructive) { discard() }.foregroundStyle(QuietLinen.danger)
                }
                Label("Stored only in this app.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 680)
        }
        .linenScreen().sheet(isPresented: $organize) { OrganizeView(tagIDs: $tagIDs).environmentObject(model) }
        .onChange(of: recorder.errorMessage) { value in error = value }
        .alert("Audio couldn’t be recorded", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Your saved items are unchanged.".gentleLocalized) }
    }

    private func saveAudio() {
        guard let url = recorder.finishedURL else { return }
        do {
            let filename = try model.store.importMedia(from: url, extension: "m4a")
            var item = LibraryItem(kind: .audio)
            item.title = title; item.isKept = kept; item.tagIDs = tagIDs
            item.encryptedMediaFilename = filename; item.mediaFileExtension = "m4a"; item.duration = recorder.elapsed
            try model.saveLibraryItem(item)
            if let onSaved { onSaved() } else { dismiss() }
        } catch let caughtError { error = caughtError.localizedDescription }
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
                        ProgressView("Opening private media…")
                    }
                    metadata(for: item)
                    Button { toggleKept(item) } label: { Label((item.isKept ? "Remove from Kept" : "Keep").gentleLocalized, systemImage: "bookmark") }
                        .buttonStyle(SecondaryButtonStyle())
                    if item.kind == .note { Button("Edit Details") { edit = true }.buttonStyle(SecondaryButtonStyle()) }
                    Button("Export %@".gentleLocalizedFormat(item.kind.title)) { export(item) }.buttonStyle(SecondaryButtonStyle())
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete %@".gentleLocalizedFormat(item.kind.title), systemImage: "trash") }
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
        .confirmationDialog("Delete this %@?".gentleLocalizedFormat(item?.kind.title.lowercased() ?? "item".gentleLocalized), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete %@".gentleLocalizedFormat(item?.kind.title ?? "Item".gentleLocalized), role: .destructive) {
                Task {
                    guard await model.authorizeDeletion(reason: "Confirm deletion of this private library item.".gentleLocalized) else { return }
                    do { try model.deleteLibraryItem(itemID); dismiss() } catch { self.error = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes it from this iPhone. It cannot be undone.") }
        .alert("This item couldn’t be opened", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Try again.".gentleLocalized) }
    }

    private func metadata(for item: LibraryItem) -> some View {
        let tags = model.vault.tags.filter { item.tagIDs.contains($0.id) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags) { Text($0.displayName).padding(.horizontal, 10).padding(.vertical, 6).background(QuietLinen.clay.opacity(0.2), in: Capsule()) }
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
            guard await model.authenticateSensitiveAction(reason: "Confirm export of this private %@.".gentleLocalizedFormat(item.kind.title.lowercased())) else { return }
            do {
                exportURL = try ExportService(store: model.store).libraryItem(item, format: item.kind == .note ? .pdf : .originalMedia)
                share = true
            } catch { self.error = error.localizedDescription }
        }
    }
}

struct TagsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTagID: UUID?
    @State private var newTag = ""
    @State private var search = ""
    @State private var editingTag: LibraryTag?
    private var visibleTags: [LibraryTag] {
        let tags = search.isEmpty ? model.vault.tags : model.vault.tags.filter { $0.displayName.localizedCaseInsensitiveContains(search) }
        return tags.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    var body: some View {
        List {
            Section {
                Button {
                    selectedTagID = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text("All Library Items")
                        Spacer()
                        Text(model.vault.libraryItems.count.formatted()).foregroundStyle(QuietLinen.muted)
                        if selectedTagID == nil { Image(systemName: "checkmark") }
                    }
                }
                .buttonStyle(.plain)
                HStack {
                    TextField("New tag", text: $newTag)
                    Button("Add") {
                        if !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            _ = try? model.addTag(named: newTag)
                            newTag = ""
                        }
                    }
                }
            }
            Section {
                ForEach(visibleTags) { tag in
                    HStack(spacing: 10) {
                        Button {
                            selectedTagID = tag.id
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "tag")
                                Text(tag.displayName)
                                Spacer()
                                Text(model.vault.libraryItems.filter { $0.tagIDs.contains(tag.id) }.count.formatted())
                                    .font(.caption).foregroundStyle(QuietLinen.muted)
                                if selectedTagID == tag.id { Image(systemName: "checkmark") }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if tag.defaultKind == nil {
                            Button { editingTag = tag } label: {
                                Image(systemName: "pencil").frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit %@".gentleLocalizedFormat(tag.displayName))
                        }
                    }
                }
            } header: {
                Text("Tags")
            } footer: {
                Text("Use tags to group and find Library items. Included tags are always available; you can create, rename, and delete your own.")
            }
        }
        .searchable(text: $search, prompt: "Search tags")
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Tags")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .sheet(item: $editingTag) { tag in
            NavigationStack { EditTagView(tag: tag, selectedTagID: $selectedTagID) }
        }
    }
}

struct EditTagView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let tag: LibraryTag
    @Binding var selectedTagID: UUID?
    @State private var name: String
    @State private var confirmDelete = false

    init(tag: LibraryTag, selectedTagID: Binding<UUID?>) {
        self.tag = tag
        self._selectedTagID = selectedTagID
        self._name = State(initialValue: tag.name)
    }

    var body: some View {
        Form {
            Section("Tag name") { TextField("Tag name", text: $name) }
            Button("Save Tag") {
                try? model.renameTag(tag.id, to: name)
                dismiss()
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Delete Tag", role: .destructive) { confirmDelete = true }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Edit Tag")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .confirmationDialog("Delete this tag?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Tag", role: .destructive) {
                if selectedTagID == tag.id { selectedTagID = nil }
                try? model.deleteTag(tag.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Deleting a tag does not delete the items that use it.") }
    }
}
