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
    let title: LocalizedStringKey
    let body: LocalizedStringKey
    let note: LocalizedStringKey?
}

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0

    private let pages = [
        OnboardingPage(icon: nil,
                       title: "A private place for your story.",
                       body: "Use a journal when you want structure. Keep notes, videos, and audio in your private library.",
                       note: "There is no schedule to keep."),
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
                        .foregroundStyle(QuietLinen.forest)
                        .padding(22)
                        .background(QuietLinen.sage.opacity(0.2), in: Circle())
                }
                Text(pages[page].title).editorialTitle()
                Text(pages[page].body)
                    .font(.body).multilineTextAlignment(.center).lineSpacing(4)
                if let note = pages[page].note {
                    Text(note).font(.footnote).foregroundStyle(QuietLinen.muted).multilineTextAlignment(.center)
                }
                Spacer()
                Button((page == pages.count - 1 ? "Turn On App Lock" : "Continue").gentleLocalized) { advance() }
                    .buttonStyle(PrimaryButtonStyle())
                if page == pages.count - 1 {
                    Button("Not Now") {
                        model.preferences.appLockEnabled = false
                        model.setOnboardingComplete()
                    }.buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(28)
            .frame(maxWidth: 560)
        }
    }

    private func advance() {
        if page < pages.count - 1 { withAnimation(.easeInOut(duration: 0.2)) { page += 1 } }
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
    @State private var requestedInitialUnlock = false
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
                Button { Task { _ = await model.unlock() } } label: {
                    if model.isAuthenticating {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock")
                    }
                }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(model.isAuthenticating)
                Button("Need support now?") { showHelp = true }
                    .foregroundStyle(QuietLinen.ink).underline()
            }
            .padding(28).frame(maxWidth: 520)
        }
        .sheet(isPresented: $showHelp) { NavigationStack { HelpSafetyView() } }
        .task {
            guard !requestedInitialUnlock else { return }
            requestedInitialUnlock = true
            _ = await model.unlock()
        }
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
