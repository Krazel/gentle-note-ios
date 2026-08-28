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
        .background(KeyboardDismissInstaller())
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
                case .reflections: MealReflectionsRootView()
                case .library: LibraryRootView()
                case .settings: SettingsRootView()
                }
            }
            RootTabBar(selection: $model.selectedTab)
        }
        .linenScreen()
    }
}

enum OnboardingStep: Int, CaseIterable, Equatable {
    case welcome
    case overview
    case appLock
}

struct OnboardingFlowState: Equatable {
    var step: OnboardingStep = .welcome

    mutating func advance() {
        switch step {
        case .welcome: step = .overview
        case .overview: step = .appLock
        case .appLock: break
        }
    }

    mutating func skipTour() {
        guard step == .overview else { return }
        step = .appLock
    }
}

struct OnboardingOverviewItem: Identifiable, Equatable {
    let icon: String
    let title: String
    let body: String

    var id: String { title }
}

let onboardingOverviewItems = [
    OnboardingOverviewItem(icon: "book.closed",
                           title: "Journal",
                           body: "Write freely or choose a template. There is nothing to keep up with."),
    OnboardingOverviewItem(icon: "books.vertical",
                           title: "Library",
                           body: "Keep private notes, images, videos, and audio to return to whenever you choose."),
    OnboardingOverviewItem(icon: "pencil",
                           title: "Meal Reflections",
                           body: "Reflect in your own words on moments related to food. It is always optional.")
]

private struct OnboardingPage {
    let icon: String?
    let title: String
    let body: String
    let note: String?
}

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var flow = OnboardingFlowState()

    private let welcome = OnboardingPage(icon: nil,
                                         title: "A private place for your story.",
                                         body: "Use a journal when you want structure. Keep notes, images, videos, and audio in your private library.",
                                         note: "There is no schedule to keep.")
    private let appLock = OnboardingPage(icon: "lock.fill",
                                         title: "Protect your private space.",
                                         body: "Use Face ID, Touch ID, or your iPhone passcode. Someone who knows your iPhone passcode may still be able to unlock Gentle Note.",
                                         note: "Deleting the app or losing this iPhone may permanently remove your content.")

    var body: some View {
        GeometryReader { proxy in
            PaperBackground()
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        if flow.step == .overview {
                            Button("Skip tour".gentleLocalized) { skipTour() }
                                .foregroundStyle(QuietLinen.forest)
                                .underline()
                                .frame(minHeight: 44)
                        }
                    }
                    .frame(minHeight: 44)

                    OnboardingProgressIndicator(step: flow.step)

                    Spacer(minLength: flow.step == .overview ? 0 : 20)

                    if flow.step == .overview {
                        overviewContent
                    } else {
                        standardContent(flow.step == .welcome ? welcome : appLock)
                    }

                    Spacer(minLength: 20)

                    Button(primaryActionTitle) { advance() }
                        .buttonStyle(PrimaryButtonStyle())

                    if flow.step == .appLock {
                        Button("Not Now".gentleLocalized) {
                            model.preferences.appLockEnabled = false
                            model.setOnboardingComplete()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
    }

    private var primaryActionTitle: String {
        switch flow.step {
        case .welcome: "Continue".gentleLocalized
        case .overview: "Continue to App Lock".gentleLocalized
        case .appLock: "Turn On App Lock".gentleLocalized
        }
    }

    private func standardContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Text("Gentle Note").font(.system(.title2, design: .serif))
            BotanicalSprig()
            if let icon = page.icon {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(QuietLinen.forest)
                    .padding(22)
                    .background(QuietLinen.sage.opacity(0.2), in: Circle())
                    .accessibilityHidden(true)
            }
            Text(page.title.gentleLocalized).editorialTitle()
            Text(page.body.gentleLocalized)
                .font(.body)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            if let note = page.note {
                Text(note.gentleLocalized)
                    .font(.footnote)
                    .foregroundStyle(QuietLinen.muted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var overviewContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "books.vertical")
                .font(.system(size: 32))
                .foregroundStyle(QuietLinen.forest)
                .padding(20)
                .background(QuietLinen.sage.opacity(0.2), in: Circle())
                .accessibilityHidden(true)

            Text("Three spaces, each with its own purpose.".gentleLocalized)
                .editorialTitle()

            VStack(spacing: 12) {
                ForEach(onboardingOverviewItems) { item in
                    LinenCard {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .foregroundStyle(QuietLinen.forest)
                                .frame(minWidth: 34, maxWidth: 34, minHeight: 44, alignment: .top)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title.gentleLocalized)
                                    .font(.system(.title3, design: .serif, weight: .medium))
                                    .foregroundStyle(QuietLinen.ink)
                                Text(item.body.gentleLocalized)
                                    .font(.body)
                                    .foregroundStyle(QuietLinen.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func advance() {
        if flow.step == .appLock {
            model.preferences.appLockEnabled = true
            model.setOnboardingComplete()
            Task { _ = await model.unlock() }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { flow.advance() }
        }
    }

    private func skipTour() {
        withAnimation(.easeInOut(duration: 0.2)) { flow.skipTour() }
    }
}

private struct OnboardingProgressIndicator: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { candidate in
                Circle()
                    .fill(candidate == step ? QuietLinen.forest : QuietLinen.line)
                    .frame(width: candidate == step ? 8 : 7, height: candidate == step ? 8 : 7)
            }
        }
        .accessibilityHidden(true)
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
                Text("Unlock to open your private space.")
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
