import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

private struct ReflectionEditorSeed: Identifiable {
    let id = UUID()
    var existingID: UUID?
    var mainPhotoData: Data?
    var mainPhotoExtension = "jpg"
    var additionalPhotos: [ReflectionSeedImage] = []
}

private struct ReflectionSeedImage {
    var data: Data
    var fileExtension: String
}

private struct ReflectionDraftAttachment: Identifiable {
    var id = UUID()
    var kind: ReflectionAttachmentKind
    var fileExtension: String
    var duration: TimeInterval?
    var existingFilename: String?
    var temporaryURL: URL?
    var imageData: Data?
    var createdAt = Date()
}

struct MealReflectionsRootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var editorSeed: ReflectionEditorSeed?
    @State private var showCamera = false
    @State private var cameraDenied = false
    @State private var loadingPhoto = false
    @State private var error: String?

    private var reflections: [MealReflection] {
        model.vault.mealReflections.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if model.showsMealReflectionIntroduction {
                        sectionIntroduction
                    }
                    captureActions
                    if !reflections.isEmpty {
                        ReflectionHistoryList(reflections: reflections)
                    }
                }
                .padding(20)
                .frame(maxWidth: 720)
            }
            .linenScreen()
            .navigationTitle("Intakes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ReflectionCalendarScreen(reflections: reflections)
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("Open Calendar")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                MealReflectionDetailView(reflectionID: id)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            PhotoCapturePicker { image in
                guard let data = image.jpegData(compressionQuality: 0.9) else {
                    error = "This photo couldn’t be prepared.".gentleLocalized
                    return
                }
                editorSeed = ReflectionEditorSeed(mainPhotoData: data)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $editorSeed) { seed in
            NavigationStack { MealReflectionEditorView(seed: seed) }
        }
        .onChange(of: selectedPhotos) { loadSelectedPhotos($0) }
        .alert("Camera is off", isPresented: $cameraDenied) {
            Button("Open iPhone Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Gentle Note cannot take a photo without camera access. You can change this in iPhone Settings.")
        }
        .alert("This photo couldn’t be added", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Try another image.".gentleLocalized) }
    }

    private var sectionIntroduction: some View {
        LinenCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(QuietLinen.forest)
                    .frame(minWidth: 34, maxWidth: 34, minHeight: 44, alignment: .top)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remember each intake in context")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(QuietLinen.forest)
                    Text("Keep one or more photos of an intake with the words, audio, or video that help you remember what was happening and how the moment felt.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    model.setMealReflectionIntroductionVisible(false)
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide this introduction")
            }
        }
    }

    private var captureActions: some View {
        VStack(spacing: 10) {
            Button { openCamera() } label: {
                Label("Take a Photo", systemImage: "camera.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 20, matching: .images) {
                if loadingPhoto {
                    ProgressView()
                } else {
                    Label("Choose Photos", systemImage: "photo.on.rectangle")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(loadingPhoto)
        }
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

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        loadingPhoto = true
        Task {
            do {
                var loaded: [ReflectionSeedImage] = []
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          UIImage(data: data) != nil else { throw CocoaError(.fileReadCorruptFile) }
                    let ext = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?
                        .preferredFilenameExtension ?? "jpg"
                    loaded.append(ReflectionSeedImage(data: data, fileExtension: ext))
                }
                guard let main = loaded.first else { throw CocoaError(.fileReadUnknown) }
                await MainActor.run {
                    selectedPhotos = []
                    loadingPhoto = false
                    editorSeed = ReflectionEditorSeed(mainPhotoData: main.data,
                                                      mainPhotoExtension: main.fileExtension,
                                                      additionalPhotos: Array(loaded.dropFirst()))
                }
            } catch {
                await MainActor.run {
                    selectedPhotos = []
                    loadingPhoto = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

private struct ReflectionCalendarScreen: View {
    let reflections: [MealReflection]

    var body: some View {
        ScrollView {
            ReflectionCalendarView(reflections: reflections)
                .padding(20)
                .frame(maxWidth: 720)
        }
        .linenScreen()
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReflectionHistoryList: View {
    @EnvironmentObject private var model: AppModel
    let reflections: [MealReflection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your intakes").font(.system(.title2, design: .serif))
            ForEach(reflections) { reflection in
                NavigationLink(value: reflection.id) {
                    HStack(spacing: 14) {
                        if model.showsMealReflectionPreviews {
                            PrivateReflectionImage(filename: reflection.mainPhotoFilename,
                                                   fileExtension: reflection.mainPhotoExtension)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.title2).foregroundStyle(QuietLinen.forest)
                                .frame(width: 70, height: 70)
                                .background(QuietLinen.sage.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(reflection.displayTitle).font(.headline)
                            Text(reflection.reflectionDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(QuietLinen.muted)
                            Text("%d attachment(s)".gentleLocalizedFormat(reflection.attachments.count))
                                .font(.caption2).foregroundStyle(QuietLinen.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(QuietLinen.muted)
                    }
                    .padding(12)
                    .background(QuietLinen.paperRaised, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ReflectionCalendarView: View {
    let reflections: [MealReflection]
    @State private var visibleMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var selectedDate = Date()
    private let calendar = Calendar.current

    private var selectedReflections: [MealReflection] {
        reflections.filter { calendar.isDate($0.reflectionDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 16) {
            LinenCard {
                VStack(spacing: 12) {
                    HStack {
                        Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                            .accessibilityLabel("Previous month")
                        Spacer()
                        Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.system(.headline, design: .serif))
                        Spacer()
                        Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                            .accessibilityLabel("Next month")
                    }
                    calendarGrid
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(selectedDate.formatted(date: .long, time: .omitted))
                    .font(.system(.headline, design: .serif))
                if selectedReflections.isEmpty {
                    Text("No intake saved for this day.")
                        .foregroundStyle(QuietLinen.muted)
                } else {
                    ForEach(selectedReflections) { reflection in
                        NavigationLink(value: reflection.id) {
                            HStack {
                                Image(systemName: "camera.macro").foregroundStyle(QuietLinen.forest)
                                VStack(alignment: .leading) {
                                    Text(reflection.displayTitle).font(.headline)
                                    Text(reflection.reflectionDate.formatted(date: .omitted, time: .shortened))
                                        .font(.caption).foregroundStyle(QuietLinen.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(QuietLinen.muted)
                            }
                            .padding(12).background(QuietLinen.paperRaised, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        let leading = leadingBlankCount()
        let symbols = rotatedWeekdaySymbols()
        return VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(symbols, id: \.self) { symbol in
                    Text(symbol).font(.caption2).foregroundStyle(QuietLinen.muted)
                }
                ForEach(0..<leading, id: \.self) { _ in Color.clear.frame(height: 42) }
                ForEach(days, id: \.self) { date in dayButton(date) }
            }
        }
    }

    private func dayButton(_ date: Date) -> some View {
        let count = reflections.filter { calendar.isDate($0.reflectionDate, inSameDayAs: date) }.count
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text(String(calendar.component(.day, from: date))).font(.subheadline)
                HStack(spacing: 2) {
                    ForEach(0..<min(count, 3), id: \.self) { _ in
                        Circle().fill(QuietLinen.clay).frame(width: 4, height: 4)
                    }
                }.frame(height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(selected ? QuietLinen.sage.opacity(0.35) : Color.clear, in: Circle())
            .foregroundStyle(QuietLinen.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .long, time: .omitted))
        .accessibilityValue(count == 0 ? "No intakes".gentleLocalized : "%d intake(s)".gentleLocalizedFormat(count))
    }

    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: visibleMonth) else { return [] }
        return range.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: visibleMonth)
        }
    }

    private func leadingBlankCount() -> Int {
        let weekday = calendar.component(.weekday, from: visibleMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private func rotatedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private func moveMonth(_ amount: Int) {
        guard let month = calendar.date(byAdding: .month, value: amount, to: visibleMonth) else { return }
        visibleMonth = month
        selectedDate = month
    }
}

private struct MealReflectionEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let seed: ReflectionEditorSeed

    @State private var mainPhotoData: Data?
    @State private var mainPhotoExtension = "jpg"
    @State private var existingMainFilename: String?
    @State private var mainPhotoChanged = false
    @State private var words = ""
    @State private var guidedAnswers = Array(repeating: "", count: IntakeGuidePrompt.allCases.count)
    @State private var showsGuidedQuestions = false
    @State private var reflectionDate = Date()
    @State private var mealMoment: MealMoment?
    @State private var attachments: [ReflectionDraftAttachment] = []
    @State private var originalCreatedAt = Date()
    @State private var loadedExisting = false
    @State private var saved = false
    @State private var saving = false

    @State private var replacementPhoto: PhotosPickerItem?
    @State private var additionalPhotos: [PhotosPickerItem] = []
    @State private var selectedVideo: PhotosPickerItem?
    @State private var showMainCamera = false
    @State private var showAdditionalCamera = false
    @State private var showAudioImporter = false
    @State private var showAudioRecorder = false
    @State private var showVideoRecorder = false
    @State private var cameraDenied = false
    @State private var microphoneDenied = false
    @State private var videoPermissionDenied = false
    @State private var error: String?

    init(seed: ReflectionEditorSeed) {
        self.seed = seed
        _mainPhotoData = State(initialValue: seed.mainPhotoData)
        _mainPhotoExtension = State(initialValue: seed.mainPhotoExtension)
        _mainPhotoChanged = State(initialValue: seed.mainPhotoData != nil)
        _attachments = State(initialValue: seed.additionalPhotos.map {
            ReflectionDraftAttachment(kind: .image,
                                      fileExtension: $0.fileExtension,
                                      duration: nil,
                                      imageData: $0.data)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let mainPhotoData, let image = UIImage(data: mainPhotoData) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxHeight: 430)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("Main photo")
                } else {
                    ProgressView("Opening private photo…").frame(minHeight: 240)
                }

                HStack(spacing: 10) {
                    Button { requestMainCamera() } label: {
                        Label("Retake Photo", systemImage: "camera")
                    }.buttonStyle(.bordered)
                    PhotosPicker(selection: $replacementPhoto, matching: .images) {
                        Label("Choose Different", systemImage: "photo.on.rectangle")
                    }.buttonStyle(.bordered)
                }

                LinenCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When was this?").font(.headline)
                        DatePicker("Intake date", selection: $reflectionDate,
                                   displayedComponents: [.date, .hourAndMinute])
                        Text("Optional meal label").font(.headline)
                        mealMomentChips
                    }
                }

                LinenCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add words, if you want").font(.headline)
                        Text("What happened? How did it feel? What did you need, what helped, or what would you like to remember?")
                            .font(.footnote).foregroundStyle(QuietLinen.muted)
                        LinenTextEditor(prompt: "Write only what feels useful…".gentleLocalized,
                                        text: $words, minHeight: 130)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showsGuidedQuestions.toggle()
                            }
                        } label: {
                            Label(showsGuidedQuestions ? "Hide guided questions" : "Use guided questions",
                                  systemImage: "list.bullet.rectangle")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(QuietLinen.forest)

                        if showsGuidedQuestions {
                            Divider()
                            Text("Guided intake check-in").font(.headline)
                            Text("Use this when you want to notice the context around an intake—what was happening, what you felt, and what support might help.")
                                .font(.footnote).foregroundStyle(QuietLinen.muted)
                            ForEach(Array(IntakeGuidePrompt.allCases.enumerated()), id: \.element.id) { index, prompt in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(prompt.question).font(.subheadline.weight(.medium))
                                    LinenTextEditor(prompt: "Your words…", text: guidedBinding(for: index), minHeight: 88,
                                                    accessibilityName: prompt.question)
                                }
                            }
                        }
                    }
                }

                layerPicker

                if !attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Added to this intake").font(.headline)
                        ForEach(attachments) { attachment in attachmentRow(attachment) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(20).frame(maxWidth: 720)
        }
        .linenScreen()
        .navigationTitle(seed.existingID == nil ? "New Intake" : "Edit Intake")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(mainPhotoData == nil || saving)
            }
        }
        .task { loadExistingIfNeeded() }
        .onChange(of: replacementPhoto) { loadImage($0, asMainPhoto: true) }
        .onChange(of: additionalPhotos) { loadAdditionalImages($0) }
        .onChange(of: selectedVideo) { loadVideo($0) }
        .fullScreenCover(isPresented: $showMainCamera) {
            PhotoCapturePicker { image in setCameraImage(image, asMainPhoto: true) }.ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showAdditionalCamera) {
            PhotoCapturePicker { image in setCameraImage(image, asMainPhoto: false) }.ignoresSafeArea()
        }
        .sheet(isPresented: $showAudioRecorder) {
            NavigationStack {
                ReflectionAudioRecorderSheet { url, duration in
                    attachments.append(ReflectionDraftAttachment(kind: .audio,
                                                                 fileExtension: "m4a",
                                                                 duration: duration,
                                                                 temporaryURL: url))
                }
            }
        }
        .sheet(isPresented: $showVideoRecorder) {
            NavigationStack {
                ReflectionVideoRecorderSheet { url, duration in
                    attachments.append(ReflectionDraftAttachment(kind: .video,
                                                                 fileExtension: "mov",
                                                                 duration: duration,
                                                                 temporaryURL: url))
                }
            }
        }
        .fileImporter(isPresented: $showAudioImporter, allowedContentTypes: [.audio]) { importAudio($0) }
        .onDisappear { if !saved { removeUnsavedTemporaryFiles() } }
        .alert("Camera is off", isPresented: $cameraDenied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot take a photo without camera access. You can change this in iPhone Settings.") }
        .alert("Microphone is off", isPresented: $microphoneDenied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record audio without microphone access. You can change this in iPhone Settings.") }
        .alert("Camera and microphone are off", isPresented: $videoPermissionDenied) {
            Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Gentle Note cannot record a video without access. You can change this in iPhone Settings.") }
        .alert("This intake couldn’t be saved", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("Keep Editing") { error = nil }
        } message: { Text(error ?? "Your saved intakes are unchanged.".gentleLocalized) }
    }

    private var mealMomentChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MealMoment.allCases) { moment in
                    Button {
                        mealMoment = mealMoment == moment ? nil : moment
                    } label: {
                        HStack(spacing: 5) {
                            if mealMoment == moment { Image(systemName: "checkmark") }
                            Text(moment.title)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(mealMoment == moment ? QuietLinen.sage.opacity(0.45) : QuietLinen.paper,
                                    in: Capsule())
                        .overlay(Capsule().stroke(QuietLinen.sage.opacity(0.65)))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var layerPicker: some View {
        LinenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos, audio, and video").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    attachmentAction("Take Another Photo", icon: "camera") {
                        requestAdditionalCamera()
                    }
                    PhotosPicker(selection: $additionalPhotos, maxSelectionCount: 20, matching: .images) {
                        attachmentActionLabel("Choose Photos", icon: "photo.on.rectangle")
                    }
                    attachmentAction("Record Audio", icon: "mic") {
                        requestAudioRecording()
                    }
                    attachmentAction("Choose Audio File", icon: "folder") {
                        showAudioImporter = true
                    }
                    attachmentAction("Record Video", icon: "video") {
                        requestVideoRecording()
                    }
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        attachmentActionLabel("Choose Video", icon: "film")
                    }
                }
            }
        }
    }

    private func attachmentAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            attachmentActionLabel(title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private func attachmentActionLabel(_ title: String, icon: String) -> some View {
        Label(title.gentleLocalized, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .padding(.horizontal, 12)
            .background(QuietLinen.paper, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(QuietLinen.sage.opacity(0.65)))
            .foregroundStyle(QuietLinen.ink)
    }

    private func attachmentRow(_ attachment: ReflectionDraftAttachment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: attachment.kind.icon).foregroundStyle(QuietLinen.forest)
                .frame(width: 30, height: 30).background(QuietLinen.sage.opacity(0.2), in: Circle())
            VStack(alignment: .leading) {
                Text(attachment.kind.title)
                if let duration = attachment.duration {
                    Text(duration.clockString).font(.caption).foregroundStyle(QuietLinen.muted)
                }
            }
            Spacer()
            Button(role: .destructive) { removeAttachment(attachment) } label: {
                Image(systemName: "trash")
            }.accessibilityLabel("Remove attachment")
        }
        .padding(12).background(QuietLinen.paperRaised, in: RoundedRectangle(cornerRadius: 14))
    }

    private func loadExistingIfNeeded() {
        guard !loadedExisting, let id = seed.existingID,
              let reflection = model.vault.mealReflections.first(where: { $0.id == id }) else { return }
        loadedExisting = true
        existingMainFilename = reflection.mainPhotoFilename
        mainPhotoExtension = reflection.mainPhotoExtension
        words = reflection.words
        guidedAnswers = normalizedGuidedAnswers(reflection.guidedAnswers)
        showsGuidedQuestions = guidedAnswers.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        reflectionDate = reflection.reflectionDate
        mealMoment = reflection.mealMoment
        originalCreatedAt = reflection.createdAt
        attachments = reflection.attachments.map {
            ReflectionDraftAttachment(id: $0.id, kind: $0.kind,
                                      fileExtension: $0.mediaFileExtension,
                                      duration: $0.duration,
                                      existingFilename: $0.encryptedMediaFilename,
                                      createdAt: $0.createdAt)
        }
        do {
            let url = try model.store.readableMediaURL(filename: reflection.mainPhotoFilename,
                                                       extension: reflection.mainPhotoExtension)
            mainPhotoData = try Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
        } catch { self.error = error.localizedDescription }
    }

    private func requestMainCamera() { requestCamera { showMainCamera = true } }
    private func requestAdditionalCamera() { requestCamera { showAdditionalCamera = true } }

    private func requestCamera(onAllowed: @escaping @MainActor () -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "The camera is unavailable.".gentleLocalized
            return
        }
        Task {
            if await MediaPermissions.requestCamera() { onAllowed() }
            else { cameraDenied = true }
        }
    }

    private func requestAudioRecording() {
        Task {
            if await MediaPermissions.requestMicrophone() { showAudioRecorder = true }
            else { microphoneDenied = true }
        }
    }

    private func requestVideoRecording() {
        Task {
            if await MediaPermissions.requestCameraAndMicrophone() { showVideoRecorder = true }
            else { videoPermissionDenied = true }
        }
    }

    private func setCameraImage(_ image: UIImage, asMainPhoto: Bool) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            error = "This photo couldn’t be prepared.".gentleLocalized
            return
        }
        if asMainPhoto {
            mainPhotoData = data; mainPhotoExtension = "jpg"; mainPhotoChanged = true
        } else {
            attachments.append(ReflectionDraftAttachment(kind: .image,
                                                         fileExtension: "jpg",
                                                         duration: nil,
                                                         imageData: data))
        }
    }

    private func loadImage(_ item: PhotosPickerItem?, asMainPhoto: Bool) {
        guard let item else { return }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      UIImage(data: data) != nil else { throw CocoaError(.fileReadCorruptFile) }
                let ext = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?
                    .preferredFilenameExtension ?? "jpg"
                await MainActor.run {
                    if asMainPhoto {
                        mainPhotoData = data; mainPhotoExtension = ext; mainPhotoChanged = true
                        replacementPhoto = nil
                    }
                }
            } catch { await MainActor.run { self.error = error.localizedDescription } }
        }
    }

    private func loadAdditionalImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            do {
                var loaded: [ReflectionDraftAttachment] = []
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          UIImage(data: data) != nil else { throw CocoaError(.fileReadCorruptFile) }
                    let ext = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?
                        .preferredFilenameExtension ?? "jpg"
                    loaded.append(ReflectionDraftAttachment(kind: .image,
                                                            fileExtension: ext,
                                                            duration: nil,
                                                            imageData: data))
                }
                await MainActor.run {
                    attachments.append(contentsOf: loaded)
                    additionalPhotos = []
                }
            } catch {
                await MainActor.run {
                    additionalPhotos = []
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func loadVideo(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                guard let picked = try await item.loadTransferable(type: PickedVideoFile.self) else {
                    throw CocoaError(.fileReadUnknown)
                }
                defer { try? FileManager.default.removeItem(at: picked.url) }
                let ext = picked.url.pathExtension.isEmpty ? "mov" : picked.url.pathExtension
                let destination = model.store.temporaryURL.appendingPathComponent(UUID().uuidString + "." + ext)
                try FileManager.default.copyItem(at: picked.url, to: destination)
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                      ofItemAtPath: destination.path)
                let seconds = AVURLAsset(url: destination).duration.seconds
                await MainActor.run {
                    attachments.append(ReflectionDraftAttachment(kind: .video,
                                                                 fileExtension: ext,
                                                                 duration: seconds.isFinite ? seconds : nil,
                                                                 temporaryURL: destination))
                    selectedVideo = nil
                }
            } catch { await MainActor.run { selectedVideo = nil; self.error = error.localizedDescription } }
        }
    }

    private func importAudio(_ result: Result<URL, Error>) {
        do {
            let selected = try result.get()
            let accessing = selected.startAccessingSecurityScopedResource()
            defer { if accessing { selected.stopAccessingSecurityScopedResource() } }
            let ext = selected.pathExtension.isEmpty ? "m4a" : selected.pathExtension
            let destination = model.store.temporaryURL.appendingPathComponent(UUID().uuidString + "." + ext)
            try FileManager.default.copyItem(at: selected, to: destination)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                  ofItemAtPath: destination.path)
            let seconds = AVURLAsset(url: destination).duration.seconds
            attachments.append(ReflectionDraftAttachment(kind: .audio,
                                                         fileExtension: ext,
                                                         duration: seconds.isFinite ? seconds : nil,
                                                         temporaryURL: destination))
        } catch { self.error = error.localizedDescription }
    }

    private func removeAttachment(_ attachment: ReflectionDraftAttachment) {
        if let url = attachment.temporaryURL { try? FileManager.default.removeItem(at: url) }
        attachments.removeAll { $0.id == attachment.id }
    }

    private func save() {
        guard let mainPhotoData else { return }
        saving = true
        var imported = Set<String>()
        do {
            let mainFilename: String
            if mainPhotoChanged || existingMainFilename == nil {
                let source = try protectedTemporaryFile(data: mainPhotoData, extension: mainPhotoExtension)
                mainFilename = try model.store.importMedia(from: source, extension: mainPhotoExtension)
                imported.insert(mainFilename)
            } else {
                mainFilename = existingMainFilename!
            }

            var savedAttachments: [ReflectionAttachment] = []
            for attachment in attachments {
                if let existingFilename = attachment.existingFilename {
                    savedAttachments.append(ReflectionAttachment(id: attachment.id,
                                                                 kind: attachment.kind,
                                                                 encryptedMediaFilename: existingFilename,
                                                                 mediaFileExtension: attachment.fileExtension,
                                                                 duration: attachment.duration,
                                                                 createdAt: attachment.createdAt))
                } else {
                    let source: URL
                    if let imageData = attachment.imageData {
                        source = try protectedTemporaryFile(data: imageData, extension: attachment.fileExtension)
                    } else if let temporaryURL = attachment.temporaryURL {
                        source = temporaryURL
                    } else {
                        throw CocoaError(.fileNoSuchFile)
                    }
                    let filename = try model.store.importMedia(from: source, extension: attachment.fileExtension)
                    imported.insert(filename)
                    savedAttachments.append(ReflectionAttachment(id: attachment.id,
                                                                 kind: attachment.kind,
                                                                 encryptedMediaFilename: filename,
                                                                 mediaFileExtension: attachment.fileExtension,
                                                                 duration: attachment.duration,
                                                                 createdAt: attachment.createdAt))
                }
            }

            var reflection = MealReflection(id: seed.existingID ?? UUID(),
                                            mainPhotoFilename: mainFilename,
                                            mainPhotoExtension: mainPhotoExtension,
                                            words: words,
                                            guidedAnswers: guidedAnswers.map {
                                                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                            },
                                            attachments: savedAttachments,
                                            reflectionDate: reflectionDate,
                                            mealMoment: mealMoment,
                                            createdAt: seed.existingID == nil ? Date() : originalCreatedAt,
                                            updatedAt: Date())
            reflection.words = words.trimmingCharacters(in: .whitespacesAndNewlines)
            try model.saveMealReflection(reflection, newlyImportedFilenames: imported)
            saved = true
            dismiss()
        } catch {
            for filename in imported { try? model.store.removeMedia(filename: filename) }
            saving = false
            self.error = error.localizedDescription
        }
    }

    private func guidedBinding(for index: Int) -> Binding<String> {
        Binding(get: {
            index < guidedAnswers.count ? guidedAnswers[index] : ""
        }, set: { value in
            guidedAnswers = normalizedGuidedAnswers(guidedAnswers)
            guidedAnswers[index] = value
        })
    }

    private func normalizedGuidedAnswers(_ answers: [String]) -> [String] {
        var result = Array(answers.prefix(IntakeGuidePrompt.allCases.count))
        while result.count < IntakeGuidePrompt.allCases.count { result.append("") }
        return result
    }

    private func protectedTemporaryFile(data: Data, extension ext: String) throws -> URL {
        let url = model.store.temporaryURL.appendingPathComponent(UUID().uuidString + "." + ext)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                              ofItemAtPath: url.path)
        return url
    }

    private func removeUnsavedTemporaryFiles() {
        for attachment in attachments where attachment.existingFilename == nil {
            if let url = attachment.temporaryURL { try? FileManager.default.removeItem(at: url) }
        }
    }
}

private struct ReflectionAudioRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorder()
    @State private var delivered = false
    let onFinished: (URL, TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Intake audio").editorialTitle()
            DecorativeWaveform(level: recorder.level).frame(height: 120)
            Text(recorder.elapsed.clockString).font(.title2)
            if recorder.finishedURL == nil {
                HStack(spacing: 24) {
                    if recorder.isRecording {
                        Button(recorder.isPaused ? "Resume" : "Pause") { recorder.pauseOrResume() }
                            .buttonStyle(.bordered)
                    }
                    Button { recorder.isRecording ? recorder.stop() : recorder.start() } label: {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.system(size: 66)).foregroundStyle(QuietLinen.clay)
                    }
                }
            } else {
                Button("Add Audio") {
                    guard let url = recorder.finishedURL else { return }
                    delivered = true; onFinished(url, recorder.elapsed); dismiss()
                }.buttonStyle(PrimaryButtonStyle())
                Button("Record Again") {
                    if let url = recorder.finishedURL { try? FileManager.default.removeItem(at: url) }
                    recorder.finishedURL = nil; recorder.start()
                }.buttonStyle(SecondaryButtonStyle())
            }
            Label("This recording will be attached only when you save the intake.", systemImage: "lock")
                .font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24).linenScreen().navigationTitle("Record Audio").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onDisappear { if !delivered { recorder.cancelAndDiscard() } }
    }
}

private struct ReflectionVideoRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VideoRecorder()
    @State private var delivered = false
    let onFinished: (URL, TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 16) {
            CameraPreview(session: recorder.session)
                .frame(maxWidth: .infinity).aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(recorder.elapsed.clockString).font(.title2)
            if recorder.finishedURL == nil {
                HStack {
                    Button { recorder.flipCamera() } label: { Image(systemName: "arrow.triangle.2.circlepath.camera") }
                        .disabled(recorder.isRecording)
                    Spacer()
                    Button { recorder.isRecording ? recorder.stop() : recorder.start() } label: {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.system(size: 66)).foregroundStyle(QuietLinen.clay)
                    }.disabled(!recorder.isReady && !recorder.isRecording)
                    Spacer()
                    Image(systemName: "mic.fill")
                }
            } else {
                Button("Add Video") {
                    guard let url = recorder.finishedURL else { return }
                    let seconds = AVURLAsset(url: url).duration.seconds
                    delivered = true
                    onFinished(url, seconds.isFinite ? seconds : recorder.elapsed); dismiss()
                }.buttonStyle(PrimaryButtonStyle())
                Button("Record Again") {
                    if let url = recorder.finishedURL { try? FileManager.default.removeItem(at: url) }
                    recorder.finishedURL = nil; recorder.start()
                }.buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
        }
        .padding(20).linenScreen().navigationTitle("Record Video").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        .onAppear { recorder.configure() }
        .onDisappear {
            if !delivered { recorder.cancelAndDiscard() }
            recorder.stopSession()
        }
    }
}

private struct PrivateReflectionImage: View {
    @EnvironmentObject private var model: AppModel
    let filename: String
    let fileExtension: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { ProgressView() }
        }
        .task(id: filename) { load() }
    }

    private func load() {
        do {
            let url = try model.store.readableMediaURL(filename: filename, extension: fileExtension)
            let data = try Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
            image = UIImage(data: data)
        } catch { image = nil }
    }
}

struct MealReflectionDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let reflectionID: UUID
    @State private var editSeed: ReflectionEditorSeed?
    @State private var confirmDelete = false
    @State private var shareItems: [URL] = []
    @State private var sharing = false
    @State private var error: String?

    private var reflection: MealReflection? {
        model.vault.mealReflections.first { $0.id == reflectionID }
    }

    var body: some View {
        ScrollView {
            if let reflection {
                VStack(spacing: 16) {
                    PrivateReflectionImage(filename: reflection.mainPhotoFilename,
                                           fileExtension: reflection.mainPhotoExtension)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    Text(reflection.displayTitle).editorialTitle()
                    Text(reflection.reflectionDate.formatted(date: .long, time: .shortened))
                        .font(.caption).foregroundStyle(QuietLinen.muted)
                    if !reflection.words.isEmpty {
                        LinenCard { Text(reflection.words).frame(maxWidth: .infinity, alignment: .leading) }
                    }
                    ForEach(Array(IntakeGuidePrompt.allCases.enumerated()), id: \.element.id) { index, prompt in
                        if index < reflection.guidedAnswers.count,
                           !reflection.guidedAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            LinenCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(prompt.question).font(.subheadline.weight(.semibold))
                                    Text(reflection.guidedAnswers[index])
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    ForEach(reflection.attachments) { attachment in
                        PrivateReflectionAttachmentView(attachment: attachment)
                    }
                    Button("Edit Intake") {
                        editSeed = ReflectionEditorSeed(existingID: reflection.id)
                    }.buttonStyle(SecondaryButtonStyle())
                    Button("Export Intake") { export(reflection) }.buttonStyle(SecondaryButtonStyle())
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete Intake", systemImage: "trash")
                    }.buttonStyle(SecondaryButtonStyle()).foregroundStyle(QuietLinen.danger)
                    Label("Stored encrypted on this iPhone.", systemImage: "lock.fill")
                        .font(.footnote).foregroundStyle(QuietLinen.muted)
                }.padding(20).frame(maxWidth: 720)
            }
        }
        .linenScreen().navigationTitle("Intake").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $editSeed) { seed in
            NavigationStack { MealReflectionEditorView(seed: seed) }
        }
        .sheet(isPresented: $sharing) {
            ActivitySheet(items: shareItems) { try? model.store.clearTemporaryFiles() }
        }
        .confirmationDialog("Delete this intake?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Intake", role: .destructive) {
                Task {
                    guard await model.authorizeDeletion(reason: "Confirm deletion of this private intake.".gentleLocalized) else { return }
                    do { try model.deleteMealReflection(reflectionID); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes its photo, words, and attachments from this iPhone. It cannot be undone.") }
        .alert("This intake couldn’t be opened", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) { Button("Done") { error = nil } }
        message: { Text(error ?? "Try again.".gentleLocalized) }
    }

    private func export(_ reflection: MealReflection) {
        Task {
            guard await model.authenticateSensitiveAction(reason: "Confirm export of this private intake.".gentleLocalized) else { return }
            do {
                shareItems = try ExportService(store: model.store).mealReflection(reflection)
                sharing = true
            } catch { self.error = error.localizedDescription }
        }
    }
}

private struct PrivateReflectionAttachmentView: View {
    @EnvironmentObject private var model: AppModel
    let attachment: ReflectionAttachment
    @State private var readableURL: URL?
    @State private var error = false

    var body: some View {
        LinenCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(attachment.kind.title, systemImage: attachment.kind.icon).font(.headline)
                if let readableURL {
                    MediaPlayerView(url: readableURL, kind: attachment.kind.libraryKind)
                    if let duration = attachment.duration {
                        Text(duration.clockString).font(.caption).foregroundStyle(QuietLinen.muted)
                    }
                } else if error {
                    Text("This attachment couldn’t be opened.").foregroundStyle(QuietLinen.danger)
                } else {
                    ProgressView("Opening private media…")
                }
            }
        }
        .task(id: attachment.id) { open() }
        .onDisappear { if let readableURL { try? FileManager.default.removeItem(at: readableURL) } }
    }

    private func open() {
        do {
            readableURL = try model.store.readableMediaURL(filename: attachment.encryptedMediaFilename,
                                                           extension: attachment.mediaFileExtension)
        } catch { self.error = true }
    }
}

struct ReflectionPrivacyView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var warning = false
    @State private var shareItems: [URL] = []
    @State private var sharing = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Toggle("Show Photo Previews", isOn: Binding(
                    get: { model.showsMealReflectionPreviews },
                    set: { model.setMealReflectionPreviewsVisible($0) }
                )).tint(QuietLinen.forest)
            } footer: {
                Text("When off, history shows a quiet placeholder instead of each main photo. Full photos remain visible inside an intake.")
            }
            Section("Export") {
                Button("Export All Intakes") { warning = true }
                    .disabled(model.vault.mealReflections.isEmpty)
                Text("Nothing is exported automatically. The destination you choose controls any copies outside Gentle Note.")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            Section("Section visibility") {
                Button("Hide Intakes") {
                    model.setMealReflectionsEnabled(false)
                    dismiss()
                }
                Text("This removes the section from the navigation without deleting anything. You can show it again from Settings.")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            Section("Private by design") {
                Text("Intakes, dates, photos, words, audio, and video stay encrypted on this iPhone. Gentle Note does not create an account, sync them, analyze them, or use them for statistics.")
                Text("This is a private intake journal, not treatment or a required food log.")
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Intake Privacy")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .confirmationDialog("Your export leaves the app", isPresented: $warning, titleVisibility: .visible) {
            Button("Continue to Export") { exportAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Gentle Note cannot protect or delete copies saved outside the app.")
        }
        .sheet(isPresented: $sharing) {
            ActivitySheet(items: shareItems) { try? model.store.clearTemporaryFiles() }
        }
        .alert("The export couldn’t be created", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) { Button("Done") { error = nil } }
        message: { Text(error ?? "Nothing was shared. Try again.".gentleLocalized) }
    }

    private func exportAll() {
        Task {
            guard await model.authenticateSensitiveAction(reason: "Confirm export of all private intakes.".gentleLocalized) else { return }
            do {
                shareItems = try ExportService(store: model.store).allMealReflections(model.vault.mealReflections)
                sharing = true
            } catch { self.error = error.localizedDescription }
        }
    }
}
