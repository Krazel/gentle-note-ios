import SwiftUI

struct JournalRootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showTemplates = false
    @State private var showBlank = false
    @State private var showHistory = false
    @State private var showHelp = false
    @State private var draftTemplate: JournalTemplateID?

    private var recent: [JournalEntry] {
        model.vault.journalEntries.sorted { $0.createdAt > $1.createdAt }.prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    BotanicalSprig()
                    Text("Your journal").editorialTitle()
                    Text("Start blank or choose a gentle template.\nNothing is due.")
                        .multilineTextAlignment(.center).foregroundStyle(QuietLinen.muted)

                    if let draft = model.vault.journalDraft {
                        Button { showComposer(for: draft.templateID) } label: {
                            LinenCard {
                                HStack {
                                    Image(systemName: "doc.text")
                                    VStack(alignment: .leading) {
                                        Text("Continue Draft").font(.headline)
                                        Text("Saved on this iPhone · \(draft.savedAt.gentleDate)")
                                            .font(.caption).foregroundStyle(QuietLinen.muted)
                                    }
                                    Spacer(); Image(systemName: "chevron.right")
                                }
                            }
                        }.buttonStyle(.plain)
                    }

                    Image(systemName: "book.pages")
                        .font(.system(size: 52)).foregroundStyle(QuietLinen.ochre)
                        .accessibilityHidden(true)

                    Button("New Journal Entry") { showTemplates = model.preferences.showGuidedTemplates; showBlank = !showTemplates }
                        .buttonStyle(PrimaryButtonStyle())
                    HStack(spacing: 12) {
                        Button { showBlank = true } label: { Label("Start Blank", systemImage: "pencil") }
                            .buttonStyle(SecondaryButtonStyle())
                        if model.preferences.showGuidedTemplates {
                            Button { showTemplates = true } label: { Label("Choose a Template", systemImage: "square.grid.2x2") }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }

                    if !recent.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent entries").font(.headline)
                            ForEach(recent) { entry in
                                NavigationLink(value: entry) { JournalRow(entry: entry) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    Button("View Journal History") { showHistory = true }
                        .foregroundStyle(QuietLinen.ink).underline()
                        .accessibilityHint("Opens all saved journal entries")
                    Button("Need support now?") { showHelp = true }
                        .font(.footnote).foregroundStyle(QuietLinen.ink).underline()
                }
                .padding(20).frame(maxWidth: 680)
            }
            .navigationDestination(for: JournalEntry.self) { JournalDetailView(entryID: $0.id) }
            .navigationTitle("")
        }
        .sheet(isPresented: $showTemplates) { NavigationStack { TemplateLibraryView() } }
        .sheet(isPresented: $showBlank) { NavigationStack { JournalComposerView(templateID: .blank) } }
        .sheet(isPresented: $showHistory) { NavigationStack { JournalHistoryView() } }
        .sheet(isPresented: $showHelp) { NavigationStack { HelpSafetyView() } }
        .sheet(item: $draftTemplate) { template in NavigationStack { JournalComposerView(templateID: template) } }
    }

    private func showComposer(for template: JournalTemplateID) {
        draftTemplate = template
    }
}

struct JournalRow: View {
    @EnvironmentObject private var model: AppModel
    let entry: JournalEntry
    var body: some View {
        LinenCard {
            HStack(spacing: 12) {
                Image(systemName: entry.templateID.icon).foregroundStyle(QuietLinen.forest)
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.displayTitle).font(.system(.body, design: .serif))
                    Text(entry.createdAt.gentleDate).font(.caption).foregroundStyle(QuietLinen.muted)
                    if model.preferences.showJournalPreviews {
                        Text(entry.searchableText).lineLimit(2).font(.caption).foregroundStyle(QuietLinen.muted)
                    }
                }
                Spacer()
                if entry.isKept { Image(systemName: "bookmark.fill").accessibilityLabel("Kept") }
                Image(systemName: "chevron.right").font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.templateID.title), \(entry.createdAt.gentleDate)\(entry.isKept ? ", " + "Kept".gentleLocalized : "")")
    }
}

struct TemplateLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: JournalTemplateID?
    var body: some View {
        List {
            Section {
                ForEach(JournalTemplateID.allCases.filter { $0 != .blank }) { template in
                    Button { selected = template } label: {
                        HStack {
                            Image(systemName: template.icon).foregroundStyle(QuietLinen.forest).frame(width: 28)
                            VStack(alignment: .leading) {
                                Text(template.title).font(.system(.body, design: .serif))
                                if let subtitle = template.subtitle {
                                    Text(subtitle).font(.caption).foregroundStyle(QuietLinen.muted)
                                }
                            }
                            Spacer(); Image(systemName: "chevron.right")
                        }
                        .frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
            } header: {
                VStack(spacing: 8) {
                    BotanicalSprig()
                    Text("Choose a template").editorialTitle()
                    Text("Use a structure, start blank, or leave. Every prompt is optional.")
                        .font(.footnote).multilineTextAlignment(.center)
                }.textCase(nil).frame(maxWidth: .infinity)
            } footer: {
                Text("Reflection templates are not therapy or medical advice.")
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            }
            Section {
                Button("Start Blank") { selected = .blank }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .scrollContentBackground(.hidden).linenScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        .sheet(item: $selected) { template in NavigationStack { JournalComposerView(templateID: template) } }
    }
}

struct JournalComposerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let templateID: JournalTemplateID
    var existingID: UUID?
    @State private var title = ""
    @State private var entryText = ""
    @State private var answers: [String] = []
    @State private var kept = false
    @State private var showDiscard = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(templateID.title).font(.system(.title2, design: .serif))
                if let subtitle = templateID.subtitle {
                    Text(subtitle).font(.caption).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(QuietLinen.sage.opacity(0.2), in: Capsule())
                }
                Text(templateID.intro).font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
                TextField("Optional title", text: $title)
                    .textFieldStyle(.roundedBorder).accessibilityLabel("Optional title")
                if templateID == .blank {
                    LinenTextEditor(prompt: "Write whatever feels useful…", text: $entryText, minHeight: 330)
                } else {
                    ForEach(Array(templateID.prompts.enumerated()), id: \.offset) { index, prompt in
                        LinenTextEditor(prompt: prompt, text: binding(for: index), minHeight: 96)
                    }
                }
                Toggle(isOn: $kept) {
                    Label("Keep this entry easy to find", systemImage: kept ? "bookmark.fill" : "bookmark")
                }.tint(QuietLinen.forest)
                Button("Save Entry") { save() }.buttonStyle(PrimaryButtonStyle())
                Text("You can stop here. Nothing is due.").font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(20).frame(maxWidth: 700)
        }
        .linenScreen().navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showDiscard = hasContent } } }
        .onAppear { load() }
        .onChange(of: title) { _ in saveDraft() }
        .onChange(of: entryText) { _ in saveDraft() }
        .onChange(of: answers) { _ in saveDraft() }
        .confirmationDialog("Keep this draft?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Keep Draft") { saveDraft(); dismiss() }
            Button("Discard Draft", role: .destructive) { model.saveJournalDraft(nil); dismiss() }
            Button("Keep Writing", role: .cancel) {}
        } message: { Text("Your draft is stored only on this iPhone.") }
        .alert("This entry couldn’t be saved", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Keep Editing") { error = nil }
        } message: { Text(error ?? "Your previous saved version is unchanged. Keep this screen open and try again.".gentleLocalized) }
    }

    private var hasContent: Bool {
        !title.isEmpty || !entryText.isEmpty || answers.contains(where: { !$0.isEmpty })
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(get: { index < answers.count ? answers[index] : "" },
                set: { value in
                    while answers.count <= index { answers.append("") }
                    answers[index] = value
                })
    }

    private func load() {
        answers = Array(repeating: "", count: templateID.prompts.count)
        if let existingID, let entry = model.vault.journalEntries.first(where: { $0.id == existingID }) {
            title = entry.title; entryText = entry.body; answers = entry.answers; kept = entry.isKept
        } else if let draft = model.vault.journalDraft, draft.templateID == templateID {
            title = draft.title; entryText = draft.body; answers = draft.answers; kept = draft.isKept
        }
    }

    private func saveDraft() {
        guard existingID == nil, hasContent else { return }
        model.saveJournalDraft(JournalDraft(templateID: templateID, title: title, body: entryText,
                                            answers: answers, isKept: kept, savedAt: Date()))
    }

    private func save() {
        var entry = existingID.flatMap { id in model.vault.journalEntries.first { $0.id == id } }
            ?? JournalEntry(templateID: templateID)
        entry.title = title; entry.body = entryText; entry.answers = answers; entry.isKept = kept; entry.updatedAt = Date()
        guard !entry.isEmpty else { error = "There is nothing to save yet."; return }
        do { try model.saveJournalEntry(entry); dismiss() }
        catch { self.error = error.localizedDescription }
    }
}

struct JournalHistoryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var filter = 0

    private var entries: [JournalEntry] {
        model.vault.journalEntries
            .filter { filter == 0 || (filter == 1 && $0.templateID == .blank) || (filter == 2 && $0.templateID != .blank) || (filter == 3 && $0.isKept) }
            .filter { query.isEmpty || $0.searchableText.localizedCaseInsensitiveContains(query) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(0); Text("Blank").tag(1); Text("Templates").tag(2); Text("Kept").tag(3)
                }.pickerStyle(.segmented)
            }
            if entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "leaf")
                        .font(.title2)
                        .foregroundStyle(QuietLinen.sage)
                    Text((query.isEmpty ? "No entries yet" : "No entries matched").gentleLocalized)
                        .font(.headline)
                    Text((query.isEmpty ? "Write when it feels useful—there’s no schedule to keep." : "Try different words or clear the filters.").gentleLocalized)
                        .font(.subheadline)
                        .foregroundStyle(QuietLinen.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .listRowBackground(Color.clear)
            } else {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) { JournalRow(entry: entry) }
                }
            }
        }
        .searchable(text: $query, prompt: "Search entries")
        .overlay(alignment: .top) {
            if !query.isEmpty { Text("Search happens on this iPhone.").font(.caption).foregroundStyle(QuietLinen.muted).padding(.top, 6) }
        }
        .scrollContentBackground(.hidden).linenScreen()
        .navigationTitle("Journal History")
        .navigationDestination(for: JournalEntry.self) { JournalDetailView(entryID: $0.id) }
    }
}

struct JournalDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let entryID: UUID
    @State private var edit = false
    @State private var confirmDelete = false
    @State private var exportURL: URL?
    @State private var share = false

    private var entry: JournalEntry? { model.vault.journalEntries.first { $0.id == entryID } }

    var body: some View {
        ScrollView {
            if let entry {
                VStack(alignment: .leading, spacing: 14) {
                    Text(entry.displayTitle).editorialTitle().frame(maxWidth: .infinity)
                    Text(entry.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption).foregroundStyle(QuietLinen.muted).frame(maxWidth: .infinity)
                    if !entry.body.isEmpty { LinenCard { Text(entry.body).frame(maxWidth: .infinity, alignment: .leading) } }
                    ForEach(Array(entry.answers.enumerated()), id: \.offset) { index, answer in
                        if !answer.isEmpty {
                            LinenCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    if index < entry.templateID.prompts.count {
                                        Text(entry.templateID.prompts[index]).font(.system(.body, design: .serif))
                                    }
                                    Text(answer)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    Button { toggleKept(entry) } label: {
                        Label((entry.isKept ? "Remove from Kept" : "Keep").gentleLocalized, systemImage: entry.isKept ? "bookmark.fill" : "bookmark")
                    }.buttonStyle(SecondaryButtonStyle())
                    Button("Edit") { edit = true }.buttonStyle(SecondaryButtonStyle())
                    Button("Export Entry") { export(entry) }.buttonStyle(SecondaryButtonStyle())
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete Entry", systemImage: "trash") }
                        .buttonStyle(SecondaryButtonStyle()).foregroundStyle(QuietLinen.danger)
                    Text("This entry is stored on this iPhone.").font(.footnote).foregroundStyle(QuietLinen.muted).frame(maxWidth: .infinity)
                }.padding(20).frame(maxWidth: 700)
            }
        }
        .linenScreen().navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $edit) { if let entry { NavigationStack { JournalComposerView(templateID: entry.templateID, existingID: entry.id) } } }
        .sheet(isPresented: $share) { if let exportURL { ActivitySheet(items: [exportURL]) { try? model.store.clearTemporaryFiles() } } }
        .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Entry", role: .destructive) {
                Task {
                    guard await model.authorizeDeletion(reason: "Confirm deletion of this journal entry.".gentleLocalized) else { return }
                    try? model.deleteJournalEntry(entryID); dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes the entry from this iPhone. It cannot be undone.") }
    }

    private func toggleKept(_ entry: JournalEntry) {
        var changed = entry; changed.isKept.toggle(); changed.updatedAt = Date(); try? model.saveJournalEntry(changed)
    }

    private func export(_ entry: JournalEntry) {
        Task {
            guard await model.authenticateSensitiveAction(reason: "Confirm export of your private journal.".gentleLocalized) else { return }
            exportURL = try? ExportService(store: model.store).journalEntry(entry, format: .pdf)
            share = exportURL != nil
        }
    }
}
