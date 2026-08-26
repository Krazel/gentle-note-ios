import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            if !model.preferences.onboardingComplete {
                OnboardingView()
            } else if model.preferences.appLockEnabled && !model.isUnlocked {
                LockedView()
            } else {
                MainShell()
            }
            if model.privacyCoverVisible {
                PaperBackground()
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill").font(.system(size: 42)).foregroundStyle(QuietLinen.forest)
                    Text("Gentle Note").editorialTitle()
                }
            }
        }
        .alert("Something needs attention", isPresented: Binding(
            get: { model.lastError != nil },
            set: { if !$0 { model.lastError = nil } })) {
                Button("Done") { model.lastError = nil }
            } message: { Text(model.lastError ?? "") }
    }
}

struct MainShell: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch model.selectedTab {
                case .journal: JournalRootView()
                case .library: LibraryRootView()
                case .settings: SettingsRootView()
                }
            }
            RootTabBar(selection: $model.selectedTab)
        }
        .linenScreen()
    }
}

private struct OnboardingPage {
    let icon: String?
    let title: String
    let body: String
    let note: String?
}

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0
    @State private var understood = false

    private let pages = [
        OnboardingPage(icon: nil,
                       title: "A private place for your story.",
                       body: "Use a journal when you want structure. Keep notes, videos, and audio in your private library.",
                       note: "There is no schedule to keep."),
        OnboardingPage(icon: "lock.shield",
                       title: "Your words and recordings stay with you.",
                       body: "The app does not collect or sync your journal, notes, videos, or audio. They stay in this app unless you choose to export them.",
                       note: "No account. No ads. No analytics."),
        OnboardingPage(icon: "heart",
                       title: "A note about care.",
                       body: "Gentle Note is a private reflection tool. It does not diagnose, monitor, or treat an eating disorder, and nobody reviews what you save.",
                       note: "It cannot respond in an emergency."),
        OnboardingPage(icon: "lock.fill",
                       title: "Protect your private space.",
                       body: "Use Face ID, Touch ID, or your iPhone passcode. Someone who knows your iPhone passcode may still be able to unlock Gentle Note.",
                       note: "Deleting the app or losing this iPhone may permanently remove your content.")
    ]

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 24) {
                Spacer()
                Text("Gentle Note").font(.system(.title2, design: .serif))
                BotanicalSprig()
                if let icon = pages[page].icon {
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundStyle(page == 2 ? QuietLinen.clay : QuietLinen.forest)
                        .padding(22)
                        .background(QuietLinen.sage.opacity(0.2), in: Circle())
                }
                Text(pages[page].title).editorialTitle()
                Text(pages[page].body)
                    .font(.body).multilineTextAlignment(.center).lineSpacing(4)
                if let note = pages[page].note {
                    Text(note).font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
                }
                if page == 2 {
                    Toggle("I understand what this journal can and cannot do.", isOn: $understood)
                        .toggleStyle(.switch).tint(QuietLinen.forest)
                }
                Spacer()
                Button(page == 3 ? "Turn On App Lock" : "Continue") { advance() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(page == 2 && !understood)
                    .opacity(page == 2 && !understood ? 0.45 : 1)
                if page == 3 {
                    Button("Not Now") {
                        model.preferences.appLockEnabled = false
                        model.setOnboardingComplete()
                    }.buttonStyle(SecondaryButtonStyle())
                }
                if page == 2 { NavigationLinkSupport() }
            }
            .padding(28)
            .frame(maxWidth: 560)
        }
    }

    private func advance() {
        if page < 3 { withAnimation(.easeInOut(duration: 0.2)) { page += 1 } }
        else {
            model.preferences.appLockEnabled = true
            model.setOnboardingComplete()
            Task { _ = await model.unlock() }
        }
    }
}

struct LockedView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showHelp = false
    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 22) {
                Text("Gentle Note").font(.system(.title2, design: .serif))
                BotanicalSprig()
                Image(systemName: "lock.fill")
                    .font(.system(size: 44)).foregroundStyle(QuietLinen.forest)
                    .padding(22).background(QuietLinen.sage.opacity(0.18), in: Circle())
                Text("Private space locked").editorialTitle()
                Text("Unlock to open your journal and library.")
                    .multilineTextAlignment(.center)
                Button("Unlock") { Task { _ = await model.unlock() } }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Need support now?") { showHelp = true }
                    .foregroundStyle(QuietLinen.ink).underline()
            }
            .padding(28).frame(maxWidth: 520)
        }
        .sheet(isPresented: $showHelp) { NavigationStack { HelpSafetyView() } }
        .task { _ = await model.unlock() }
    }
}

struct NavigationLinkSupport: View {
    @State private var showHelp = false
    var body: some View {
        Button("Need support now?") { showHelp = true }
            .foregroundStyle(QuietLinen.ink).underline()
            .sheet(isPresented: $showHelp) { NavigationStack { HelpSafetyView() } }
    }
}
