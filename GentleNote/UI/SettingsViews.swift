import AVFoundation
import MessageUI
import StoreKit
import SwiftUI
import UIKit

private let gentleNoteVersionText: String = {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    return "Version %@ (%@)".gentleLocalizedFormat(version, build)
}()

struct SettingsRootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(.privacy, "Privacy & Lock", "lock")
                    row(.permissions, "Media Permissions", "camera")
                    row(.storage, "Storage", "externaldrive")
                    row(.export, "Export", "square.and.arrow.up")
                    row(.erase, "Erase All Data", "trash", destructive: true)
                }
                Section {
                    row(.help, "Help & Safety", "questionmark.shield")
                    if SupportConfiguration.isEnabled { row(.support, "Support the App", "heart") }
                    row(.notice, "Privacy Notice", "doc.text")
                    row(.terms, "Terms of Use", "text.document")
                    row(.about, "About Gentle Note", "info.circle")
                }
                Section { Text(gentleNoteVersionText).foregroundStyle(QuietLinen.muted) }
                    footer: { Label("No account. No ads. No analytics.", systemImage: "leaf") }
            }
            .scrollContentBackground(.hidden).linenScreen().navigationTitle("Settings")
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .privacy: PrivacyLockView()
                case .permissions: MediaPermissionsView()
                case .storage: StorageView()
                case .export: ExportView()
                case .erase: EraseAllView()
                case .help: HelpSafetyView()
                case .support: SupportView()
                case .notice: PrivacyNoticeView()
                case .terms: TermsView()
                case .about: AboutView()
                }
            }
        }
    }

    private func row(_ destination: SettingsDestination, _ title: LocalizedStringKey, _ icon: String, destructive: Bool = false) -> some View {
        NavigationLink(value: destination) {
            HStack { Image(systemName: icon).frame(width: 26); Text(title); Spacer() }
                .frame(minHeight: 44).foregroundStyle(destructive ? QuietLinen.danger : QuietLinen.ink)
        }
        .buttonStyle(.plain)
    }
}

enum SettingsDestination: String, Identifiable, Hashable {
    case privacy, permissions, storage, export, erase, help, support, notice, terms, about
    var id: String { rawValue }
}

struct PrivacyLockView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmLockOff = false
    var body: some View {
        Form {
            Section {
                Toggle("App Lock", isOn: Binding(get: { model.preferences.appLockEnabled }, set: { value in
                    if value { model.preferences.appLockEnabled = true; model.savePreferences() }
                    else { confirmLockOff = true }
                }))
                .tint(QuietLinen.forest)
                Picker("Lock after leaving", selection: $model.preferences.lockDelay) {
                    ForEach(LockDelay.allCases) { Text($0.title).tag($0) }
                }.onChange(of: model.preferences.lockDelay) { _ in model.savePreferences() }
            } footer: { Text("Require Face ID, Touch ID, or your iPhone passcode to open the journal and library.") }
            Section {
                Toggle("Show Journal Previews", isOn: $model.preferences.showJournalPreviews)
                Toggle("Show Library Previews", isOn: $model.preferences.showLibraryPreviews)
                Toggle("Show Video Thumbnails", isOn: $model.preferences.showVideoThumbnails)
                Toggle("Show Guided Templates", isOn: $model.preferences.showGuidedTemplates)
            } footer: { Text("Turn off guided templates if they start to feel rigid or unhelpful. Your entries are not affected.") }
            .onChange(of: model.preferences) { _ in model.savePreferences() }
            Section("How your data is protected") {
                Text("The app does not collect or sync your journal or library. Text, metadata, and recordings are encrypted locally and use iPhone file protection. App Lock uses iPhone authentication.")
                Text("Gentle Note never receives your face, fingerprint, or passcode. Someone who knows your iPhone passcode may still be able to unlock it.")
                Text("There is no automatic recovery. Exports are separate files controlled by the destination you choose.")
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Privacy & Lock")
        .confirmationDialog("Turn off App Lock?", isPresented: $confirmLockOff, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) { model.preferences.appLockEnabled = false; model.savePreferences() }
            Button("Keep App Lock On", role: .cancel) {}
        } message: { Text("Anyone who can open your iPhone may be able to read this journal and library.") }
    }
}

struct MediaPermissionsView: View {
    var body: some View {
        List {
            PermissionStatusRow(title: "Camera", icon: "camera", state: MediaPermissions.camera())
            PermissionStatusRow(title: "Microphone", icon: "mic", state: MediaPermissions.microphone())
            HStack { Image(systemName: "photo").frame(width: 28); Text("Photos"); Spacer(); Text("Not Requested").foregroundStyle(QuietLinen.muted) }
            Section {
                Text("Gentle Note asks only when you choose to record. Nothing is saved to Photos automatically.")
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                Button("Open iPhone Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Media Permissions")
    }
}

struct StorageView: View {
    @EnvironmentObject private var model: AppModel
    private var breakdown: StorageBreakdown { model.store.storageBreakdown(for: model.vault) }
    var body: some View {
        List {
            Section("Gentle Note on this iPhone") {
                GeometryReader { proxy in
                    HStack(spacing: 1) {
                        storageSegment(breakdown.journal, total: breakdown.total, color: QuietLinen.forest, width: proxy.size.width)
                        storageSegment(breakdown.notes, total: breakdown.total, color: QuietLinen.clay, width: proxy.size.width)
                        storageSegment(breakdown.videos, total: breakdown.total, color: QuietLinen.ochre, width: proxy.size.width)
                        storageSegment(breakdown.audio, total: breakdown.total, color: QuietLinen.sage, width: proxy.size.width)
                    }.clipShape(RoundedRectangle(cornerRadius: 5))
                }.frame(height: 22).accessibilityHidden(true)
                storageRow("Journal", breakdown.journal, QuietLinen.forest)
                storageRow("Notes", breakdown.notes, QuietLinen.clay)
                storageRow("Videos", breakdown.videos, QuietLinen.ochre)
                storageRow("Audio", breakdown.audio, QuietLinen.sage)
                storageRow("Temporary Files", breakdown.temporary, QuietLinen.muted)
                HStack { Text("Total").fontWeight(.semibold); Spacer(); Text(size(breakdown.total)).foregroundStyle(QuietLinen.muted) }
                Text("Videos and audio can use substantial device storage. Gentle Note will not overwrite anything you saved.")
            }
            Section {
                HStack { Text("Video Quality"); Spacer(); Text("Space Saver · 720p").foregroundStyle(QuietLinen.muted) }
                Button("Delete Temporary Files") { try? model.store.clearTemporaryFiles() }
            }
            Section { Label("Deleting the app or losing this iPhone may remove everything.", systemImage: "exclamationmark.triangle") }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Storage")
    }

    private func storageSegment(_ value: Int64, total: Int64, color: Color, width: CGFloat) -> some View {
        color.frame(width: total > 0 ? max(2, width * CGFloat(value) / CGFloat(total)) : width / 4)
    }

    private func storageRow(_ title: LocalizedStringKey, _ bytes: Int64, _ color: Color) -> some View {
        HStack { Circle().fill(color).frame(width: 9, height: 9); Text(title); Spacer(); Text(size(bytes)).foregroundStyle(QuietLinen.muted) }
            .accessibilityElement(children: .combine)
    }

    private func size(_ bytes: Int64) -> String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
}

struct ExportView: View {
    @EnvironmentObject private var model: AppModel
    @State private var format: ExportFormat = .pdf
    @State private var warning = false
    @State private var exportURL: URL?
    @State private var share = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Choose content") {
                Label("Journal Entries", systemImage: "book.closed")
                Label("Library Notes", systemImage: "doc")
                Text("Videos and audio are exported individually from their detail screen.").font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            Section("Choose a format") {
                Picker("Format", selection: $format) {
                    Text("Readable PDF").tag(ExportFormat.pdf)
                    Text("Plain Text").tag(ExportFormat.text)
                }
            }
            Section { Button("Continue") { warning = true }.buttonStyle(PrimaryButtonStyle()) }
                footer: { Text("Nothing is exported automatically.") }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Export")
        .confirmationDialog("Your export leaves the app", isPresented: $warning, titleVisibility: .visible) {
            Button("Continue to Export") { createExport() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The destination you choose can store, back up, or share this file. Gentle Note cannot protect or delete copies outside the app.") }
        .sheet(isPresented: $share) { if let exportURL { ActivitySheet(items: [exportURL]) { try? model.store.clearTemporaryFiles() } } }
        .alert("The export couldn’t be created", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text(error ?? "Nothing was shared. Try again.".gentleLocalized) }
    }

    private func createExport() {
        Task {
            guard await model.authenticateSensitiveAction(reason: "Confirm export of your private journal and notes.".gentleLocalized) else { return }
            do { exportURL = try ExportService(store: model.store).allReadable(vault: model.vault, format: format); share = true }
            catch { self.error = error.localizedDescription }
        }
    }
}

struct EraseAllView: View {
    @EnvironmentObject private var model: AppModel
    @State private var firstConfirm = false
    @State private var finalConfirm = false
    @State private var completed = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "trash").font(.system(size: 42)).foregroundStyle(QuietLinen.danger)
                Text("Erase your journal and library").editorialTitle()
                Text("This permanently deletes every journal entry, note, video, audio recording, collection, tag, draft, and search record stored by Gentle Note on this iPhone.")
                    .multilineTextAlignment(.center)
                Text("It does not delete files you previously exported. Gentle Note cannot recover your content after erasing it.")
                    .multilineTextAlignment(.center).foregroundStyle(QuietLinen.muted)
                Button("Erase All Data", role: .destructive) { firstConfirm = true }
                    .buttonStyle(PrimaryButtonStyle()).tint(QuietLinen.danger)
            }.padding(26).frame(maxWidth: 620)
        }
        .linenScreen().navigationTitle("Erase All Data")
        .confirmationDialog("Erase everything?", isPresented: $firstConfirm, titleVisibility: .visible) {
            Button("Continue", role: .destructive) {
                Task {
                    guard await model.authenticateSensitiveAction(reason: "Confirm permanent deletion of your private journal and library.".gentleLocalized) else { return }
                    finalConfirm = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This cannot be undone.") }
        .confirmationDialog("Permanently erase Gentle Note?", isPresented: $finalConfirm, titleVisibility: .visible) {
            Button("Permanently Erase", role: .destructive) {
                do { try model.eraseEverything(); completed = true } catch { self.error = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("All content on this iPhone will be deleted now.") }
        .alert("Journal and library erased", isPresented: $completed) { Button("Done") {} }
            message: { Text("No entries, notes, recordings, drafts, collections, or tags remain in Gentle Note. Previously exported files were not changed.") }
        .alert("Gentle Note couldn’t finish erasing", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Done") { error = nil }
        } message: { Text("Some private data may still be on this iPhone. Close the app and try again. Do not assume it has been deleted.") }
    }
}

struct HelpSafetyView: View {
    @EnvironmentObject private var model: AppModel
    @State private var externalURL: URL?
    @State private var showExternal = false
    @State private var showContactEditor = false
    @State private var showMessageComposer = false
    @State private var messageError: String?

    private var usesSpainResources: Bool { Locale.current.region?.identifier == "ES" }
    private var supportMessage: String {
        "I need some support right now. Could you call or message me when you can?".gentleLocalized
    }

    var body: some View {
        List {
            Section {
                Text("Gentle Note is a private journal. It cannot see or respond to what you write, and no one is monitoring your entries. It is not a crisis or medical service.")
            }
            if usesSpainResources {
                spainResources
            } else {
                unitedStatesResources
            }
            Section("A person you trust") {
                Text("You can prepare one trusted contact. Gentle Note stores their name and phone number only on this iPhone.")
                if let contact = model.preferences.trustedContact {
                    Button { openMessage() } label: {
                        Label("Message %@".gentleLocalizedFormat(contact.name), systemImage: "message.fill")
                    }
                    Text("A message saying that you need support will be ready. iOS will ask you to confirm Send.")
                        .font(.footnote).foregroundStyle(QuietLinen.muted)
                    if model.isUnlocked {
                        Button("Edit Trusted Contact") { showContactEditor = true }
                    }
                } else if model.isUnlocked {
                    Button("Add Trusted Contact") { showContactEditor = true }
                    Text("Add a name and phone number so a support message is one tap away.")
                        .font(.footnote).foregroundStyle(QuietLinen.muted)
                } else {
                    Text("Add a trusted contact from Help & Safety after unlocking Gentle Note.")
                        .font(.footnote).foregroundStyle(QuietLinen.muted)
                }
                LinenCard { Text("You deserve care and support.\nYou are not a burden.").font(.system(.body, design: .serif)).frame(maxWidth: .infinity) }
            }
            Section {
                Text("Emergency resources are selected using your iPhone region. If you are elsewhere, contact local emergency services.")
                    .font(.footnote)
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Need support now?")
        .sheet(isPresented: $showContactEditor) {
            NavigationStack { TrustedContactEditor(contact: model.preferences.trustedContact) }
        }
        .sheet(isPresented: $showMessageComposer) {
            if let contact = model.preferences.trustedContact {
                MessageComposer(recipients: [contact.phoneNumber], body: supportMessage)
            }
        }
        .alert("Message unavailable", isPresented: Binding(get: { messageError != nil }, set: { if !$0 { messageError = nil } })) {
            Button("Done") { messageError = nil }
        } message: { Text(messageError ?? "This iPhone cannot prepare a text message right now.".gentleLocalized) }
        .confirmationDialog("Open an external resource?", isPresented: $showExternal, titleVisibility: .visible) {
            Button("Open Website") { if let externalURL { UIApplication.shared.open(externalURL) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This website has its own privacy practices. Gentle Note does not send your journal or library.") }
    }

    private func external(_ title: LocalizedStringKey, _ url: String) -> some View {
        Button { externalURL = URL(string: url); showExternal = true } label: { Label(title, systemImage: "arrow.up.right.square") }
    }

    @ViewBuilder private var spainResources: some View {
        Section("Immediate danger or urgent physical symptoms") {
            Text("If you are in Spain and may be in immediate danger, cannot stay safe, or have urgent physical symptoms—such as chest pain, trouble breathing, fainting or collapse, confusion, a seizure, uncontrolled vomiting, or blood in vomit or stool—call 112 or go to the nearest emergency department now. This is not a complete list.")
            Link(destination: URL(string: "tel:112")!) { Label("Call 112", systemImage: "phone") }
        }
        Section("Emotional crisis or suicidal thoughts") {
            Link(destination: URL(string: "tel:024")!) { Label("Call 024", systemImage: "phone") }
            external("Open the 024 online chat", "https://www.sanidad.gob.es/linea024/home.htm")
            Text("Spain’s 024 line is national, free, confidential, and available 24 hours a day. It does not replace in-person healthcare when needed.")
                .font(.footnote)
        }
        Section("Eating disorder support") {
            Text("Contact your health centre or care team for assessment and support. In an urgent situation, go to urgent care or call 112.")
            external("Find a public health centre in Spain", "https://www.sanidad.gob.es/ciudadanos/prestaciones/centrosServiciosSNS/centrosSalud/home.htm")
        }
    }

    @ViewBuilder private var unitedStatesResources: some View {
        Section("Immediate danger or urgent physical symptoms") {
            Text("If you are in the United States and may be in immediate danger, cannot stay safe, or have urgent physical symptoms—such as chest pain, trouble breathing, fainting or collapse, confusion, a seizure, uncontrolled vomiting, or blood in vomit or stool—call 911 or go to the nearest emergency department now. This is not a complete list.")
            Link(destination: URL(string: "tel:911")!) { Label("Call 911", systemImage: "phone") }
            Link(destination: URL(string: "tel:988")!) { Label("Call 988", systemImage: "phone") }
            Link(destination: URL(string: "sms:988")!) { Label("Text 988", systemImage: "message") }
            Text("The 988 Suicide & Crisis Lifeline offers free, confidential support in the United States, 24/7.").font(.footnote)
        }
        Section("Eating disorder support") {
            external("Find Eating Disorder Support", "https://www.nationaleatingdisorders.org/get-help/")
            external("Find Treatment Referrals", "https://www.allianceforeatingdisorders.com/find-treatment/")
        }
    }

    private func openMessage() {
        guard MFMessageComposeViewController.canSendText() else {
            messageError = "This iPhone cannot prepare a text message right now.".gentleLocalized
            return
        }
        showMessageComposer = true
    }
}

struct TrustedContactEditor: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phoneNumber: String
    @State private var confirmRemoval = false

    init(contact: TrustedContact?) {
        _name = State(initialValue: contact?.name ?? "")
        _phoneNumber = State(initialValue: contact?.phoneNumber ?? "")
    }

    private var normalizedPhoneNumber: String {
        phoneNumber.filter { $0.isNumber || $0 == "+" }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        normalizedPhoneNumber.filter { $0.isNumber }.count >= 6
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textContentType(.name)
                TextField("Phone number", text: $phoneNumber)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            } header: {
                Text("Trusted contact")
            } footer: {
                Text("The name and phone number are encrypted with your other local preferences. They are not uploaded or shared until you choose to message this person.")
            }
            Section("Prepared message") {
                Text("I need some support right now. Could you call or message me when you can?")
                Text("iOS always lets you review the message and requires you to tap Send.")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }
            if model.preferences.trustedContact != nil {
                Section {
                    Button("Remove Trusted Contact", role: .destructive) { confirmRemoval = true }
                }
            }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Trusted Contact")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave)
            }
        }
        .confirmationDialog("Remove trusted contact?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                model.preferences.trustedContact = nil
                model.savePreferences()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The saved name and phone number will be removed from Gentle Note.")
        }
    }

    private func save() {
        model.preferences.trustedContact = TrustedContact(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: normalizedPhoneNumber
        )
        model.savePreferences()
        dismiss()
    }
}

struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposer
        init(parent: MessageComposer) { self.parent = parent }
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            parent.dismiss()
        }
    }
}

struct PrivacyNoticeView: View {
    var body: some View {
        List {
            notice("Journal and Library", "Your entries, notes, and media are stored only on this iPhone. Gentle Note does not create an account or sync this data to a developer server.", "books.vertical")
            notice("Trusted Contact", "If you add a trusted contact, their name and phone number are encrypted on this iPhone. Gentle Note does not access your Contacts. The recipient and prepared text leave the app only when you choose to open Messages.", "person.crop.circle")
            notice("Face ID and Touch ID", "Authentication is handled by iOS. Gentle Note receives only whether authentication succeeded. It does not receive your face, fingerprint, or passcode.", "faceid")
            notice("Exporting", "When you export, you choose an external destination. The exported file is no longer protected or controlled by Gentle Note.", "square.and.arrow.up")
            notice("Retention and deletion", "Content remains on this iPhone until you delete an item, erase all data, or remove the app. The developer cannot retrieve or delete it remotely.", "trash")
            notice("No advertising or analytics", "Gentle Note has no ads, tracking, analytics, account, or third-party SDK.", "hand.raised")
            Section { Text("Gentle Note is a private reflection and personal media journal. It is not medical care, treatment, monitoring, or an emergency service.") }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Privacy Notice")
    }

    private func notice(_ title: LocalizedStringKey, _ body: LocalizedStringKey, _ icon: String) -> some View {
        Section { Text(body) } header: { Label(title, systemImage: icon) }
    }
}

struct TermsView: View {
    var body: some View {
        List {
            Section("Use of Gentle Note") { Text("Gentle Note is provided as a private reflection tool for adults. It is not medical advice, diagnosis, treatment, monitoring, or an emergency service.") }
            Section("Your content") { Text("You control what you create, export, and delete. Keep copies only in destinations you trust. The app cannot recover deleted or lost content.") }
            Section("Safety") { Text("Do not delay urgent care or professional support because of this app. Stop using it if journaling feels compulsive, punishing, or more distressing.") }
            Section("Availability") { Text("Features may change as the product is reviewed and tested. Final legal terms require review before public release.") }
        }
        .scrollContentBackground(.hidden).linenScreen().navigationTitle("Terms of Use")
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                BotanicalSprig(); Text("About Gentle Note").editorialTitle()
                Text("Gentle Note is a private reflection journal for adults living with eating disorder recovery. It is not medical care, treatment, monitoring, or an emergency service.")
                    .multilineTextAlignment(.center)
                Text("Designed to complement—not replace—professional care and personal support.")
                    .multilineTextAlignment(.center).foregroundStyle(QuietLinen.muted)
                Text(gentleNoteVersionText).font(.footnote)
            }.padding(28).frame(maxWidth: 620)
        }.linenScreen()
    }
}

struct SupportView: View {
    @StateObject private var store = SupportStore()
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                BotanicalSprig(); Text("Support the app").editorialTitle()
                Text("Every feature is available without paying. Optional support helps maintain Gentle Note. It does not unlock features or change your journal or library.")
                    .multilineTextAlignment(.center)
                ForEach(store.products, id: \.id) { product in
                    Button { Task { await store.purchase(product) } } label: {
                        VStack { Text(product.displayName); Text(product.displayPrice).font(.headline); Text("One-time").font(.caption) }
                    }.buttonStyle(SecondaryButtonStyle())
                }
                Label("Apple processes the purchase. This is not a charitable donation.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(QuietLinen.muted)
            }.padding(24).frame(maxWidth: 620)
        }
        .linenScreen().task { await store.load() }
        .alert("Support", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("Done") { store.message = nil }
        } message: { Text(store.message ?? "") }
    }
}
